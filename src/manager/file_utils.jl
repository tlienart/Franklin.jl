"""
$(SIGNATURES)

Checks for a `config.md` file in `PATHS[:src]` and uses it to set the global
variables referenced in `GLOBAL_VARS` it also sets the global latex commands
via `GLOBAL_LXDEFS`. If the configuration file is not found a warning is shown.
The keyword `init` is used internally to distinguish between the first call
where only structural variables are considered (e.g. controlling folder
structure).
"""
function process_config(; init::Bool=false)::Nothing
    # read the config.md file if it is present
    config_path = joinpath(PATHS[:src], "config.md")
    if isfile(config_path)
        convert_md(read(config_path, String); isconfig=true)
    elseif !init
        @warn "I didn't find a config file. Ignoring."
    end
    return nothing
end


"""
$(SIGNATURES)

Take a path to an input markdown file (via `root` and `file`), then construct
the appropriate HTML page (inserting `head`, `pg_foot` and `foot`) and finally
write it at the appropriate place.
"""
function write_page(root::String, file::String, head::String,
                    pg_foot::String, foot::String;
                    prerender::Bool=false, isoptim::Bool=false,
                    on_write::Function=(_, _) -> nothing)::Nothing
    # 1. read the markdown into string, convert it and extract definitions
    # 2. eval the definitions and update the variable dictionary, also retrieve
    # document variables (time of creation, time of last modif) and add those
    # to the dictionary.
    fpath = joinpath(root, file)
    # The curpath is the relative path starting after /src/ so for instance:
    # f1/blah/page1.md or index.md etc... this is useful in the code evaluation and management
    # of paths
    cur_rpath = fpath[lastindex(PATHS[:src])+length(PATH_SEP)+1:end]
    FD_ENV[:CUR_PATH] = cur_rpath

    content = convert_md(read(fpath, String))

    # Check if should add item
    # should we generate ? otherwise no
    # are we in the full pass ? otherwise no
    # is there a `rss` or `rss_description` ? otherwise no
    cond_add = GLOBAL_VARS["generate_rss"].first && # should we generate?
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
    write(joinpath(out_path(root), change_ext(file)), pg)

    on_write(pg, LOCAL_VARS)
    return nothing
end


"""
$(SIGNATURES)

See [`process_file_err`](@ref).
"""
function process_file(case::Symbol, fpair::Pair{String,String}, args...;
                      kwargs...)::Int
    try
        process_file_err(case, fpair, args...; kwargs...)
    catch err
        FD_ENV[:DEBUG_MODE] && throw(err)
        rp = fpair.first
        rp = rp[end-min(20, length(rp))+1 : end]
        println("\n... encountered an issue processing '$(fpair.second)' " *
                "in ...$rp. Verify, then start franklin again...\n")
        FD_ENV[:SUPPRESS_ERR] || @show err
        return -1
    end
    return 0
end


"""
$(SIGNATURES)

Considers a source file which, depending on `case` could be a HTML file or a
file in Franklin-Markdown etc, located in a place described by `fpair`,
processes it by converting it and adding appropriate header and footer and
writes it to the appropriate place. It can throw an error which will be
caught in `process_file(args...)`.
"""
function process_file_err(
            case::Symbol, fpair::Pair{String, String},
            head::AS="", pg_foot::AS="", foot::AS="", t::Float64=0.;
            clear::Bool=false, prerender::Bool=false, isoptim::Bool=false,
            on_write::Function=(_, _) -> nothing)::Nothing
    # depending on the file extension, either full process (.md), partial
    # process (.html) or no process (everything else)
    inp  = joinpath(fpair...)
    outp = joinpath(out_path(fpair.first), fpair.second)
    if case == :md
        write_page(fpair..., head, pg_foot, foot;
                   prerender=prerender, isoptim=isoptim, on_write=on_write)
    elseif case == :html
        raw_html  = read(inp, String)
        proc_html = convert_html(raw_html; isoptim=isoptim)
        write(outp, proc_html)
    else # case in (:other, :infra)
        # NOTE: some processing may be further added here later on (e.g.
        # parsing) of CSS files)
        # only copy again if necessary (file is not there or has changed)
        if clear || !isfile(outp) || (mtime(outp) < t && !filecmp(inp, outp))
            cp(inp, outp, force=true)
        end
    end
    FD_ENV[:FULL_PASS] || FD_ENV[:SILENT_MODE] || rprint("→ page updated [✓]")
    return nothing
end


"""
$(SIGNATURES)

Convenience function to replace the extension of a filename with another.
"""
change_ext(fname::AS, ext=".html")::String = splitext(fname)[1] * ext


"""
$(SIGNATURES)

Convenience function to assemble the html out of its parts.
"""
build_page(head::String, content::String, pg_foot::String, foot::String)::String =
    "$head\n<div class=\"franklin-content\">\n$content\n$pg_foot\n</div>\n$foot"
