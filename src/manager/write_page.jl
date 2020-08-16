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
    # <$tag class=$cclass>$content</$tag>
    body = html_content(content_tag, content * pgfoot;
                        class=content_class, id=content_id)
    return head * body * foot
end


"""
$(SIGNATURES)

Take a HTML page and apply prerendering and link fixing as appropriate.
"""
function optim_page(pg; prerender=false, isoptim=false)
    # Prerender if required (using JS tools)
    if prerender
        # Maths (KATEX)
        pg = js_prerender_katex(pg)
        # Code (HIGHLIGHT.JS)
        if FD_CAN_HIGHLIGHT
            pg = js_prerender_highlight(pg)
            # remove script
            pg = replace(pg, r"<script.*?(?:highlight\.pack\.js|initHighlightingOnLoad).*?<\/script>"=>"")
        end
        # remove katex scripts
        pg = replace(pg, r"<script.*?(?:katex\.min\.js|auto-render\.min\.js|renderMathInElement).*?<\/script>" => "")
    end
    # append pre-path to links if required (see optimize)
    if isoptim
        pg = fix_links(pg)
    end
    return pg
end


"""
$(SIGNATURES)

Write a html page at the appropriate location and with the appropriate
structure. This is usually called specifying the scaffolding but can be done
without in which case the scaffolding is read from `layout`.
"""
function write_page(output_path::AS, content::AS;
                    head::T=nothing, pgfoot::T=nothing, foot::T=nothing,
                    prerender::Bool=false, isoptim::Bool=false
                    )::String where T <: Union{Nothing,AS}
    # NOTE
    #   - output_path is assumed to exist // see form_output_path
    #   - head/pgfoot/foot === nothing --> read (see franklin.jl)
    layout = path(layout_key())
    if isnothing(head)
        head = read(joinpath(layout, "head.html"), String)
    end
    if isnothing(pgfoot)
        pgfoot = read(joinpath(layout, "page_foot.html"), String)
    end
    if isnothing(foot)
        foot = read(joinpath(layout, "foot.html"), String)
    end
    # convert the pieces
    head, ctt, pgfoot, foot = map(convert_html, (head, content, pgfoot, foot))

    # remove spurious dirs from past pagination attempts
    outdir = dirname(output_path)
    for elem in readdir(outdir)
        if all(isnumeric, elem) && first(elem) != '0'
            dpath = joinpath(outdir, elem)
            isdir(dpath) && rm(joinpath(outdir, elem), recursive=true)
        end
    end

    # the previous call possibly resolved a {{paginate}} which will have
    # stored a :paginate_itr var, so we must branch on that
    if !isnothing(locvar(:paginate_itr))
        name    = locvar(:paginate_itr)
        iter    = locvar(name)
        npp     = locvar(:paginate_npp)
        niter   = length(iter)
        n_pages = ceil(Int, niter / npp)
        for pgi = 1:n_pages
            # form the content multiple times
            sta_i = (pgi - 1) * npp + 1
            end_i = min(sta_i + npp - 1, niter)
            rge_i = sta_i:end_i
            ins_i = prod(String(e) for e in iter[rge_i])
            ctt_i = replace(ctt, PAGINATE => ins_i)
            # assemble, optimize and write
            pg = build_page(head, ctt_i, pgfoot, foot)
            pg = optim_page(pg, prerender=prerender, isoptim=isoptim)
            pgi == 1 && write(output_path, pg)
            dst = mkpath(joinpath(outdir, "$pgi"))
            write(joinpath(dst, "index.html"), pg)
        end
    else
        # convert any `{{...}}` that may be left and form the full page string
        pg = build_page(head, ctt, pgfoot, foot)
        pg = optim_page(pg, prerender=prerender, isoptim=isoptim)
        # write the html file where appropriate
        write(output_path, pg)
    end
    return pg
end


"""
$(SIGNATURES)

Take a path to an input markdown file (via `root` and `file`), then construct
the appropriate HTML page (inserting `head`, `pgfoot` and `foot`) and finally
write it at the appropriate place.
"""
function convert_and_write(root::String, file::String, head::String,
                    pgfoot::String, foot::String, output_path::String;
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

    pg = write_page(output_path, content; head=head, pgfoot=pgfoot, foot=foot,
                    prerender=prerender, isoptim=isoptim)

    # 6. possible post-processing via the "on-write" function.
    on_write(pg, LOCAL_VARS)
    return nothing
end
