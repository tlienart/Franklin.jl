"""
$(SIGNATURES)

Create and/or update `__site/tag` folders/files. It takes the set of tags to
refresh (in which case only the pages associated to those tags will be
refreshed) or an empty set in which case all tags will be (re)-generated.
"""
function generate_tag_pages(refresh_tags=Set{String}())::Nothing
    # filter out pages that may not exist anymore
    PAGE_TAGS = globvar("fd_page_tags")
    for rpath in keys(PAGE_TAGS)
        isfile(rpath * ".md") || delete!(PAGE_TAGS, rpath)
    end
    isempty(PAGE_TAGS) && return nothing

    # Get the dictionary tag -> [rp1, rp2...]
    TAG_PAGES = invert_dict(PAGE_TAGS)
    # store it in globvar
    empty!(globvar("fd_tag_pages"))
    merge!(globvar("fd_tag_pages"), TAG_PAGES)

    #
    all_tags  = collect(keys(TAG_PAGES))

    # check if the tag dir is there
    isdir(path(:tag)) || mkpath(path(:tag))
    # cleanup any page that may still be there but shouldn't
    for dirname in setdiff(readdir(path(:tag)), all_tags)
        rm(joinpath(path(:tag), dirname), recursive=true)
    end

    layout_key  = ifelse(FD_ENV[:STRUCTURE] < v"0.2", :src_html, :layout)
    layout      = path(layout_key)
    head        = read(joinpath(layout, "head.html"),      String)
    pg_foot     = read(joinpath(layout, "page_foot.html"), String)
    foot        = read(joinpath(layout, "foot.html"),      String)

    for tag in (isempty(refresh_tags) ? all_tags : refresh_tags)
        # check if `tag/$tag` exists otherwise create it
        dir = joinpath(path(:tag), tag)
        isdir(dir) || mkdir(dir)
        # assemble the page using the hfun list (which can be overwritten
        # by the user)
        page = build_page(head, "{{list $tag}}", pg_foot, foot)
        # write the processed page.
        write(joinpath(dir, "index.html"), convert_html(page))
    end
    return nothing
end
