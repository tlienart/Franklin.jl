"""
$(SIGNATURES)

Convenience function to process markdown definitions `@def ...` as appropriate.
Depending on `isconfig`, will update `GLOBAL_VARS` or `LOCAL_VARS`.

**Arguments**

* `blocks`:    vector of active docs
* `isconfig`:  whether the file being processed is the config file
                (--> global page variables)
"""
function process_mddefs(blocks::Vector{OCBlock}, isconfig::Bool,
                        pagevar::Bool=false)::Nothing
    # Find all markdown definitions (MD_DEF) blocks
    mddefs = filter(β -> (β.name == :MD_DEF), blocks)
    # empty container for the assignments
    assignments = Vector{Pair{String, String}}()
    # go over the blocks, and extract the assignment
    for (i, mdd) ∈ enumerate(mddefs)
        inner = stent(mdd)
        m = match(ASSIGN_PAT, inner)
        if isnothing(m)
            @warn "Found delimiters for an @def environment but it didn't " *
                  "have the right @def var = ... format. Verify (ignoring " *
                  "for now)."
            continue
        end
        vname, vdef = m.captures[1:2]
        push!(assignments, (String(vname) => String(vdef)))
    end
    # if in config file, update `GLOBAL_VARS` and `GLOBAL_LXDEFS`
    rpath = splitext(locvar("fd_rpath"))[1]
    if isconfig
        set_vars!(GLOBAL_VARS, assignments)
        return nothing
    end
    set_vars!(LOCAL_VARS, assignments)
    rpath = splitext(locvar("fd_rpath"))[1]

    hasmath = locvar(:hasmath)
    hascode = locvar(:hascode)
    if !hascode && globvar("autocode")
        # check and set hascode automatically
        code = any(b -> startswith(string(b.name), "CODE_BLOCK"), blocks)
        set_var!(LOCAL_VARS, "hascode", code)
    end
    if !hasmath && globvar("automath")
        # check and set hasmath automatically
        math = any(b -> b.name in MATH_BLOCKS_NAMES, blocks)
        set_var!(LOCAL_VARS, "hasmath", math)
    end
    
    # copy the page vars to ALL_PAGE_VARS so that they can be accessed
    # by other pages via `pagevar`.
    ALL_PAGE_VARS[rpath] = deepcopy(LOCAL_VARS)

    # # TAGS
    # tags = Set(unique(locvar("tags")))
    # # Cases:
    # # 1. that page did not have tags
    # #   a. tags is empty --> do nothing
    # #   b. tags is not empty register them and update all
    # # 2. that page did have tags
    # #   a. tags are unchanged --> do nothing
    # #   b. check which ones change and update those
    # refresh_tags = tags
    # PAGE_TAGS    = globvar("fd_page_tags")
    # if isnothing(PAGE_TAGS)
    #     isempty(tags) && return nothing
    #     set_var!(GLOBAL_VARS, "fd_page_tags", DTAG((rpath => tags,)))
    # elseif !haskey(PAGE_TAGS, rpath)
    #     isempty(tags) && return nothing
    #     PAGE_TAGS[rpath] = tags
    # else
    #     old_tags = PAGE_TAGS[rpath]
    #     refresh_tags = setdiff(old_tags, tags)
    #     isempty(refresh_tags) && return nothing
    #     if isempty(tags)
    #         delete!(PAGE_TAGS, rpath)
    #     else
    #         PAGE_TAGS[rpath] = tags
    #     end
    # end
    # # In the full pass each page is processed first (without generating tag
    # # pages) and then, when all tags have been gathered, generate_tag_pages
    # # is called (see `fd_fullpass`).
    # # During the serve loop, we want to trigger on page change.
    # pagevar || FD_ENV[:FULL_PASS] || generate_tag_pages(refresh_tags)
    return nothing
end
