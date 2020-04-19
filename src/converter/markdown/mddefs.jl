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
    update_tags(rpath, LOCAL_VARS["tags"][1])
    return nothing
end

"""
$(SIGNATURES)

SHOULD BE PROBABLY IN A DIFFERENT FILE
Check if tags differ from TAGS[rpath]. If yes update and call `generate_tag_pages`.

**Arguments**

* `rpath`:     The relative path (can also be fetched with `splitext(locvar("fd_rpath"))[1]`)
* `tags`:      List of tags
"""
function update_tags(rpath::String, tags::Vector{String})
    # if the path had tags before
    if haskey(TAGS, rpath)
        if TAGS[rpath] != tags
            union_tags = union(TAGS[rpath], tags)
            TAGS[rpath] = tags
            generate_tag_pages(;tags=union_tags)
        end
    else
        TAGS[rpath] = tags
        generate_tag_pages(;tags=tags)
    end
end

tag_line(url, title) = "<li><a href='$url'>$title</li>"

"""
$(SIGNATURES)

SHOULD BE PROBABLY IN A DIFFERENT FILE
Create and/or update `__site/tag` folders/files

**Optional Arguments**

* `tags`:      List of changed tags. If `nothing` all tags will be updated
"""
function generate_tag_pages(;tags=nothing)
    isempty(TAGS) && return
    tags == String[] && return 
    !isdir(joinpath(path(:site), "tag")) && mkdir(joinpath(path(:site), "tag"))
    # tag => [rpath]
    inv_tags_dict = invert_dict(TAGS)
    tags === nothing && (tags = keys(inv_tags_dict))
    
    layout_key  = ifelse(FD_ENV[:STRUCTURE] < v"0.2", :src_html, :layout)
    layout      = path(layout_key)
    head        = read(joinpath(layout, "head.html"),      String)
    pg_foot     = read(joinpath(layout, "page_foot.html"), String)
    foot        = read(joinpath(layout, "foot.html"),      String)
    
    for tag in tags
        dir = joinpath(path(:site), "tag", tag)
        !isdir(dir) && mkdir(dir)
        fpath = joinpath(dir, "index.html")
        if !haskey(inv_tags_dict, tag)
            rm(fpath)
            rm(dir)
        else
            tag_content = "<h1>Tag: $tag</h1>\n"
            for rpath in inv_tags_dict[tag] 
                tag_content *= tag_line(rpath, pagevar(rpath, "title"))*"\n"
            end
            content = build_page(head, tag_content, pg_foot, foot)
            write(fpath, convert_html(content))
        end
    end
end

