"""
$(SIGNATURES)

Convenience function to assemble the html of a page out of its parts:
- head
- content and pgfoot (which will be wrapped to form the body)
- foot.
"""
function build_page(head, content, pgfoot, foot)
    # (legacy support) if div_content is offered explicitly, it takes
    # precedence, otherwise use defaults
    dc = globvar("div_content")
    if isempty(dc)
        content_tag   = globvar("content_tag")
        content_class = globvar("content_class")
        content_id    = globvar("content_id")
    else
        content_tag   = "div"
        content_class = dc
        content_id    = ""
    end
    # wrap the body in appropriate tags
    body = html_content(content_tag, content * pgfoot;
                        class=content_class, id=content_id)
    return head * body * foot
end


"""
$(SIGNATURES)

Write a html page at the appropriate location and with the appropriate structure.
This is usually called specifying the scaffolding but can be done without in which
"""
function write_page(rpath::AS, content::AS;
                    head::T=nothing, pg_foot::T=nothing, foot::T=nothing
                    )::Nothing where T <: Union{Nothing,AS}
    # NOTE
    #   - rpath is assumed to exist // see form_output_path
    #   - head/pg_foot/foot === nothing --> read (see franklin.jl)
    #   - string (possibly empty), use as such
    isnothing(head)    && (head    = read(joinpath(layout, "head.html"),      String))
    isnothing(pg_foot) && (pg_foot = read(joinpath(layout, "page_foot.html"), String))
    isnothing(foot)    && (foot    = read(joinpath(layout, "foot.html"),      String))

    page_html = build_page(head, content, pgfoot, foot)

    return
end



"""
$(SIGNATURES)

Take a path to an input markdown file (via `root` and `file`), then construct
the appropriate HTML page (inserting `head`, `pg_foot` and `foot`) and finally
write it at the appropriate place.
"""
function convert_and_write(root::String, file::String, head::String,
                    pg_foot::String, foot::String, out_path::String;
                    prerender::Bool=false, isoptim::Bool=false,
                    on_write::Function=(_,_)->nothing)::Nothing
    # 1. read the markdown into string, convert it and extract definitions
    # 2. eval the definitions and update the variable dictionary, also retrieve
    # document variables (time of creation, time of last modif) and add those
    # to the dictionary.
    fpath = joinpath(root, file)
    # The curpath is the relative path starting after /src/ so for instance:
    # f1/blah/page1.md or index.md etc... this is useful in the code evaluation
    # and management of paths
    set_cur_rpath(fpath)
    # conversion
    content = convert_md(read(fpath, String))

    # Check if should add item
    #   should we generate ? otherwise no
    #   are we in the full pass ? otherwise no
    #   is there a `rss` or `rss_description` ? otherwise no
    cond_add = GLOBAL_VARS["generate_rss"].first &&     # should we generate?
                    FD_ENV[:FULL_PASS] &&               # are we in the full pass?
                    !all(e -> isempty(locvar(e)), ("rss", "rss_description"))
    # otherwise yes
    cond_add && add_rss_item()

    # adding document variables to the dictionary
    # note that some won't change and so it's not necessary to do this every
    # time but it takes negligible time to do this so ¯\_(ツ)_/¯
    # (and it's less annoying than keeping tabs on which file has
    # already been treated etc).
    s = stat(fpath)
    set_var!(LOCAL_VARS, "fd_ctime", fd_date(unix2datetime(s.ctime)))
    set_var!(LOCAL_VARS, "fd_mtime", fd_date(unix2datetime(s.mtime)))

    # 3. process blocks in the html infra elements based on `LOCAL_VARS`
    # (e.g.: add the date in the footer)
    content = convert_html(str(content))
    head, pg_foot, foot = (e -> convert_html(e)).([head, pg_foot, foot])

    # 4. construct the page proper & prerender if needed
    pg = build_page(head, content, pg_foot, foot)
    if prerender
        # KATEX
        pg = js_prerender_katex(pg)
        # HIGHLIGHT
        if FD_CAN_HIGHLIGHT
            pg = js_prerender_highlight(pg)
            # remove script
            pg = replace(pg, r"<script.*?(?:highlight\.pack\.js|initHighlightingOnLoad).*?<\/script>"=>"")
        end
        # remove katex scripts
        pg = replace(pg, r"<script.*?(?:katex\.min\.js|auto-render\.min\.js|renderMathInElement).*?<\/script>"=>"")
    end
    # append pre-path if required (see optimize)
    if !isempty(GLOBAL_VARS["prepath"].first) && isoptim
        pg = fix_links(pg)
    end

    # 5. write the html file where appropriate
    write(out_path, pg)

    # 6. possible post-processing via the "on-write" function.
    on_write(pg, LOCAL_VARS)
    return nothing
end
