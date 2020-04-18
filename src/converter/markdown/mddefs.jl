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
        ALL_PAGE_VARS[splitext(locvar("fd_rpath"))[1]] = deepcopy(LOCAL_VARS)
    end
    return nothing
end
