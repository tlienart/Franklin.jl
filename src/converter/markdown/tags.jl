"""
$(SIGNATURES)

Create and/or update `__site/tag` folders/files. It takes the set of tags to
refresh (in which case only the pages associated to those tags will be
refreshed) or an empty set in which case all tags will be (re)-generated.
Note that if a tag is removed from a page, it may be that `refresh_tags`
contains a tag which should effectively be removed because no page have it.
(This only matters at the end in the call to `write_tag_pages`).
"""
function generate_tag_pages(refresh_tags=Set{String}())::Nothing
    # filter out pages that may not exist anymore
    PAGE_TAGS = globvar("fd_page_tags")
    isnothing(PAGE_TAGS) && return nothing
    for rpath in keys(PAGE_TAGS)
        isfile(rpath * ".md") || delete!(PAGE_TAGS, rpath)
    end
    isempty(PAGE_TAGS) && return nothing

    # Get the dictionary tag -> [rp1, rp2...]
    TAG_PAGES = invert_dict(PAGE_TAGS)
    # store it in globvar
    set_var!(GLOBAL_VARS, "fd_tag_pages", TAG_PAGES)
    all_tags = collect(keys(TAG_PAGES))

    if !isdir(path(:tag))
        mkpath(path(:tag))
    else
        # there may be tags in `refresh_tags` that are not in all_tags
        # -> in that case delete those pages
        rm_tags = filter(t -> t ∉ all_tags, refresh_tags)
        # there may also be existing dirs which shouldn't be there anymore
        # because the tags have been deleted, these two things combine but
        # can independently happen (e.g. on the main generate_tag_pages)
        for dirname in union(setdiff(readdir(path(:tag)), all_tags), rm_tags)
            rm(joinpath(path(:tag), dirname), recursive=true)
        end
    end

    # check which tags should be refreshed, note that
    update_tags = isempty(refresh_tags) ?
                    all_tags :
                    filter(t -> t ∈ all_tags, refresh_tags)
    write_tag_pages(update_tags)
    return nothing
end

"""
$SIGNATURES

Internal function to (re)write the tag pages corresponding to `update_tags`.
"""
function write_tag_pages(update_tags)::Nothing
    layout_key  = ifelse(FD_ENV[:STRUCTURE] < v"0.2", :src_html, :layout)
    layout      = path(layout_key)
    head        = read(joinpath(layout, "head.html"),      String)
    pg_foot     = read(joinpath(layout, "page_foot.html"), String)
    foot        = read(joinpath(layout, "foot.html"),      String)

    # XXX this needs to be fixed, basically tag pages should have some
    # form of page variable scope as they use the `head` and `foot` which
    # may use some `{{ ...  }}`. At the moment the tag page uses the scope
    # of the last-processed page (ambient LOCAL_VARS) which is not good.

    for tag in update_tags
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
