"""
$(SIGNATURES)

Checks for a `config.md` file and uses it to set the global variables
referenced in `GLOBAL_VARS` it also sets the global latex commands via
`GLOBAL_LXDEFS`. If the configuration file is not found a warning is shown.
The keyword `init` is used internally to distinguish between the first call
where only structural variables are considered (e.g. controlling folder
structure).
"""
function process_config(; init::Bool=false)::Nothing
    if init
        # initially the paths variable aren't set, try to find a config.md
        # and read definitions in it; in particular folder_structure.
        config_path_v1 = joinpath(FOLDER_PATH[], "src", "config.md")
        config_path_v2 = joinpath(FOLDER_PATH[], "config.md")
        if isfile(config_path_v2)
            convert_md(read(config_path_v2, String); isconfig=true)
        elseif isfile(config_path_v1)
            convert_md(read(config_path_v1, String); isconfig=true)
        else
            @warn "I didn't find a config file. Ignoring."
        end
    else
        key = ifelse(FD_ENV[:STRUCTURE] < v"0.2", :src, :folder)
        dir = path(key)
        config_path = joinpath(dir, "config.md")
        if isfile(config_path)
            convert_md(read(config_path, String); isconfig=true)
        else
            @warn "I didn't find a config file. Ignoring."
        end
    end
    return nothing
end

"""
$(SIGNATURES)

Checks for a `utils.jl` file and uses it to set global computed variables,
functions and html functions. Whatever is defined in `utils.jl` takes
precedence over things defined internally in Franklin or in the global vars;
in particular users can redefine the behaviour of `hfuns` though that's not
recommended.
"""
function process_utils()
    utils_path_v1 = joinpath(FOLDER_PATH[], "src", "utils.jl")
    utils_path_v2 = joinpath(FOLDER_PATH[], "utils.jl")
    if isfile(utils_path_v2)
        utils = utils_path_v2
    elseif isfile(utils_path_v1)
        utils = utils_path_v1
    else
        return nothing
    end
    # wipe / create module Utils
    newmodule("Utils")
    Core.eval(Main.Utils, :(include($utils)))
    # # keep track of utils names
    ns = String.(names(Main.Utils, all=true))
    filter!(n -> n[1] != '#' && n ∉ ("eval", "include", "Utils"), ns)
    empty!(UTILS_NAMES)
    append!(UTILS_NAMES, ns)
    return nothing
end


"""
$(SIGNATURES)

Take a path to an input markdown file (via `root` and `file`), then construct
the appropriate HTML page (inserting `head`, `pg_foot` and `foot`) and finally
write it at the appropriate place.
"""
function write_page(root::String, file::String, head::String,
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
    write(out_path, pg)

    # 6. possible post-processing via the "on-write" function.
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
        FD_ENV[:SUPPRESS_ERR] || throw(err)
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
            head::AS="", pgfoot::AS="", foot::AS="", t::Float64=0.;
            clear::Bool=false, prerender::Bool=false, isoptim::Bool=false,
            on_write::Function=(_,_)->nothing)::Nothing
    # depending on the file extension, either full process (.md), partial
    # process (.html) or no process (everything else)
    inp  = joinpath(fpair...)
    outp = form_output_path(fpair.first, fpair.second, case)
    if case == :md
        write_page(fpair..., head, pgfoot, foot, outp;
                   prerender=prerender, isoptim=isoptim, on_write=on_write)
    elseif case == :html
        set_cur_rpath(joinpath(fpair...))
        set_page_env()
        raw_html  = read(inp, String)
        proc_html = convert_html(raw_html; isoptim=isoptim)
        write(outp, proc_html)
    else # case in (:other, :infra)
        if FD_ENV[:STRUCTURE] >= v"0.2"
            # there's a bunch of thing we don't want to copy over
            if startswith(inp, path(:layout))   ||
                startswith(inp, path(:literate)) ||
                endswith(inp, "config.md") ||
                endswith(inp, "search.md")
                # skip
                @goto end_copyblock
            end
        end
        # NOTE: some processing may be further added here later on (e.g.
        # parsing) of CSS files)
        # only copy again if necessary (file is not there or has changed)
        if !isfile(outp) || (mtime(outp) < t && !filecmp(inp, outp))
            cp(inp, outp, force=true)
        end
        @label end_copyblock
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
build_page(head::String, content::String, pgfoot::String, foot::String) =
    "$head\n<div class=\"$(locvar("div_content"))\">\n$content\n$pgfoot\n</div>\n$foot"


"""
    get_rpath(fpath)

Extracts the relative file system path out of the full system path to a file
currently being processed. Does not start with a path separator.
So `[some_fs_path]/blog/page.md` --> `blog/page.md`.
"""
function get_rpath(fpath::String)
    root = path(ifelse(FD_ENV[:STRUCTURE] < v"0.2", :src, :folder))
    return fpath[lastindex(root)+length(PATH_SEP)+1:end]
end

"""
    set_cur_rpath(fpath)

Takes the path to the current file and sets the `fd_rpath` local page variable
as well as the `FD_ENV[:CUR_PATH]` variable (used for conditional blocks
depending on URL for instance).
"""
function set_cur_rpath(fpath::String; isrelative::Bool=false)
    if isrelative
        rpath = fpath
    else
        rpath = get_rpath(fpath)
    end
    FD_ENV[:CUR_PATH] = rpath
    set_var!(LOCAL_VARS, "fd_rpath", rpath)
    return nothing
end
