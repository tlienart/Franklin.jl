"""
$(SIGNATURES)

Convenience function to process markdown definitions `@def ...` as appropriate.
Depending on `isconfig`, will update `GLOBAL_VARS` or `LOCAL_VARS`.

**Arguments**

* `blocks`:    vector of active docs
* `isconfig`:  whether the file being processed is the config file
                (--> global page variables)
"""
function process_mddefs(blocks::Vector{OCBlock}, isconfig::Bool)::Nothing
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
    else
        set_vars!(LOCAL_VARS, assignments)

        # is hascode or hasmath set explicitly? if not and if the global
        # autocode and/or automath are left to true, then check here to see
        # if there are any blocks and set the variable automatically (#419)
        acm = filter(p -> p.first in ("hascode", "hasmath"), assignments)
        if globvar("autocode") &&
                (isempty(acm) || !any(p -> p.first == "hascode", acm))
            # check and set hascode automatically
            code = any(b -> startswith(string(b.name), "CODE_BLOCK"), blocks)
            set_var!(LOCAL_VARS, "hascode", code)
        end
        if globvar("automath") &&
                (isempty(acm) || !any(p -> p.first == "hasmath", acm))
            # check and set hasmath automatically
            math = any(b -> b.name in MATH_BLOCKS_NAMES, blocks)
            set_var!(LOCAL_VARS, "hasmath", math)
        end

        # copy the page vars to ALL_PAGE_VARS so that they can be accessed
        # by other pages via `pagevar`.
        ALL_PAGE_VARS[rpath] = deepcopy(LOCAL_VARS)
    end
    tags = Set(unique(locvar("tags")))
    # Cases:
    # 1. that page did not have tags
    #   a. tags is empty --> do nothing
    #   b. tags is not empty register them and update all
    # 2. that page did have tags
    #   a. tags are unchanged --> do nothing
    #   b. check which ones change and update those
    refresh_tags = tags
    if !haskey(PAGE_TAGS, rpath)
        isempty(tags) && return nothing
        PAGE_TAGS[rpath] = tags
    else
        old_tags = PAGE_TAGS[rpath]
        refresh_tags = setdiff(old_tags, tags)
        isempty(refresh_tags) && return nothing
        if isempty(tags)
            delete!(PAGE_TAGS, rpath)
        else
            PAGE_TAGS[rpath] = tags
        end
    end
    FD_ENV[:FULL_PASS] || generate_tag_pages(refresh_tags)
    return nothing
end

# TODO: this should be a hfun {{tagline}} which accesses pagevars, that way
# it can be over-written by the user and for instance they could add a
# short_descr page var which they would fill or put stuff in a div etc...
tag_line(url, title) = "<li><a href='$url'>$title</li>"

"""
$(SIGNATURES)

SHOULD BE PROBABLY IN A DIFFERENT FILE
Create and/or update `__site/tag` folders/files

**Optional Arguments**

* `tags`:      List of changed tags. If `nothing` all tags will be updated
"""
function generate_tag_pages(refresh_tags=Set{String}())::Nothing
    # filter out pages that may not exist anymore
    for rpath in keys(PAGE_TAGS)
        isfile(rpath * ".md") || delete!(PAGE_TAGS, rpath)
    end
    isempty(PAGE_TAGS) && return nothing

    # Get the dictionary tag -> [rp1, rp2...]
    TAG_PAGES = invert_dict(PAGE_TAGS)
    all_tags  = collect(keys(TAG_PAGES))

    # check if the tag dir is there
    isdir(path(:tag)) || mkdir(path(:tag))
    # cleanup any page that may still be there but shouldn't
    for dname in readdir(path(:tag))
        dname in all_tags || rm(joinpath(path(:tag), dname), recursive=true)
    end

    layout_key  = ifelse(FD_ENV[:STRUCTURE] < v"0.2", :src_html, :layout)
    layout      = path(layout_key)
    head        = read(joinpath(layout, "head.html"),      String)
    pg_foot     = read(joinpath(layout, "page_foot.html"), String)
    foot        = read(joinpath(layout, "foot.html"),      String)

    for tag in (isempty(refresh_tags) ? all_tags : refresh_tags)
        dir = joinpath(path(:tag), tag)
        isdir(dir) || mkdir(dir)
        fpath = joinpath(dir, "index.html")
        content = IOBuffer()
        write(content, "<h1>Tag: $tag</h1>")
        write(content, "<ul>")
        for rpath in TAG_PAGES[tag]
            write(content, tag_line("/$rpath/", pagevar(rpath, "title")))
        end
        write(content, "</ul>")
        page = build_page(head, String(take!(content)), pg_foot, foot)
        write(fpath, convert_html(page))
    end
end
