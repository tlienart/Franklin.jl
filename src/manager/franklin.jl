"""
$SIGNATURES

Clear the environment dictionaries.
"""
function clear_dicts()
    recursive_empty!.((GLOBAL_LXDEFS, GLOBAL_VARS, LOCAL_VARS, ALL_PAGE_VARS))
end

function recursive_empty!(d::AbstractDict)
    for (k, v) in d
        v isa AbstractDict && recursive_empty!(d[k])
    end
    empty!(d)
end


"""
$(SIGNATURES)

Runs Franklin in the current directory.

Keyword arguments:

* `clear=false`:     whether to remove any existing output directory
* `verb=false`:      whether to display messages
* `port=8000`:       the port to use for the local server (should pick a number
                      between 8000 and 9000)
* `single=false`:    whether to run a single pass or run continuously
* `nomess=false`:    suppresses all messages (internal use).
* `is_final_pass=false`: whether we're in a "final pass" (if so, links are
                      fixed in case of a project website, see
                      [`convert_and_write`](@ref).
* `prerender=false`: whether to pre-render javascript (KaTeX and highlight.js)
* `no_fail_prerender=true`: whether, in a prerendering phase, ignore errors and
                      try to produce an output
* `eval_all=false`:  whether to force re-evaluation of all code blocks
* `silent=false`:    switch this on to suppress all output (including eval
                      statements).
* `cleanup=true`:    whether to clear environment dictionaries, see
                      [`cleanup`](@ref).
* `on_write(pg, fd_vars)`: callback function after the page is rendered,
                      passing as arguments the rendered page and the page
                      variables
* `host="127.0.0.1"`: the host to use for the local server
* `show_warnings=true`: whether to show franklin  warnings
* `launch=!single`:   whether to launch the browser when serving
"""
function serve(; clear::Bool=false,
                 verb::Bool=false,
                 port::Int=8000,
                 single::Bool=false,
                 prerender::Bool=false,
                 nomess::Bool=false,
                 is_final_pass::Bool=false,
                 no_fail_prerender::Bool=true,
                 eval_all::Bool=false,
                 silent::Bool=false,
                 cleanup::Bool=true,
                 on_write::Function=(_, _) -> nothing,
                 log::Bool=false,
                 host::String="127.0.0.1",
                 show_warnings::Bool=true,
                 launch::Bool=!single,
                 )::Union{Nothing,Int}
    LOGGING[] = log
    # set the global path
    FOLDER_PATH[] = pwd()
    # silent mode?
    silent && (FD_ENV[:SILENT_MODE] = true; verb = false)

    if silent || !show_warnings
        FD_ENV[:SHOW_WARNINGS] = false
    end

    # in case of optim, there may be a prepath given which should be
    # kept
    prepath = get(GLOBAL_VARS, "prepath", nothing)
    def_GLOBAL_VARS!()
    isnothing(prepath) || set_var!(GLOBAL_VARS, "prepath", prepath.first)

    # Set context out of kwargs vars
    FD_ENV[:CLEAR]      = clear
    FD_ENV[:VERB]       = verb
    FD_ENV[:FINAL_PASS] = is_final_pass
    FD_ENV[:PRERENDER]  = prerender
    FD_ENV[:NO_FAIL_PRERENDER] = no_fail_prerender
    FD_ENV[:ON_WRITE]   = on_write

    # check if there's a config file, if there is, check the variable
    # definitions looking at the ones that would affect overall structure etc.
    process_config()

    if !all(isdir, (joinpath(FOLDER_PATH[], "_layout"),
                    joinpath(FOLDER_PATH[], "_css")))
        throw(ArgumentError(
            "The current directory doens't  have a `_layout` or `_css` " *
            "folder, if you are using the old folder structure, please " *
            "add `@def folder_structure = v\"0.1\"` in your config.md; " *
            "otherwise, change directory to a valid Franklin folder."))
    end

    # check if a Project.toml file is available, if so activate the folder
    flag_env = false
    if isfile(joinpath(FOLDER_PATH[], "Project.toml"))
        Pkg.activate(".")
        flag_env = true
    end

    # construct the set of files to watch
    watched_files = fd_setup()

    # set a verbosity var that we'll use in the rest of the function
    nomess && (verb = false)

    # do a first full pass
    nomess || println("→ Initial full pass...")
    start = time()
    FD_ENV[:FORCE_REEVAL] = eval_all
    sig = fd_fullpass(watched_files)
    FD_ENV[:FORCE_REEVAL] = false
    sig < 0 && return sig
    fmsg = rpad("✔ full pass...", 40)
    verb && (println(""); print(fmsg); print_final(fmsg, start); println(""))

    # start the continuous loop
    if !single
        FD_ENV[:CLEAR] = false
        nomess || println("→ Starting the server...")
        coreloopfun = (cntr, fw) -> fd_loop(cntr, fw, watched_files)
        # start the liveserver in the current directory
        live_server_dir = "__site"
        LiveServer.setverbose(verb)
        LiveServer.serve(port=port, coreloopfun=coreloopfun,
                         dir=live_server_dir, host=host, launch_browser=launch)
    end
    flag_env &&
        rprint("→ Use Pkg.activate() to go back to your main environment.")

    cleanup && clear_dicts()
    return nothing
end


"""
$(SIGNATURES)

Sets up the collection of watched files by doing an initial scan of the input
directory. It also sets the paths variables and prepares the output directory.

See also [`serve`](@ref).
"""
function fd_setup()::NamedTuple
    # . setting up:
    # -- reading and storing the path variables
    # -- setting up the output directory (see `clear`)
    set_paths!()
    prepare_output_dir()

    # . recovering the list of files in the input dir we care about
    # -- these are stored in dictionaries, the key is the full path and the
    # value is the time of last change (useful for continuous monitoring)
    md_pages         = TrackedFiles()
    html_pages       = TrackedFiles()
    other_files      = TrackedFiles()
    infra_files      = TrackedFiles()
    literate_scripts = TrackedFiles()
    # named tuples of all the watched files (order matters)
    watched_files = (other    = other_files,
                     infra    = infra_files,
                     md       = md_pages,
                     html     = html_pages,
                     literate = literate_scripts)
    # fill the dictionaries
    scan_input_dir!(watched_files...)
    return watched_files
end

"""
$(SIGNATURES)

A single full pass of Franklin looking at all watched files and processing them
as appropriate.

**Keyword arguments**

* `clear=false`:     whether to remove any existing output directory
* `verb=false`:      whether to display messages
* `is_final_pass=false` : whether it's the final pass before deployment
* `prerender=false`: whether to prerender katex and code blocks
* `no_fail_prerender=true`: whether to skip if a prerendering goes wrong in which case don't prerender

See also [`fd_loop`](@ref), [`serve`](@ref) and [`publish`](@ref).
"""
function fd_fullpass(watched_files::NamedTuple)::Int
    # keep track of context (some things either will or won't be done on
    # the full pass, e.g. see tag generation)
    FD_ENV[:FULL_PASS]  = true

    # reset global page variables and latex definitions
    # NOTE: need to keep track of pre-path if specified, see optimize
    prepath = get(GLOBAL_VARS, "prepath", "")
    def_GLOBAL_VARS!()
    def_GLOBAL_LXDEFS!()
    empty!(RSS_DICT)
    # reinsert prepath if specified
    isempty(prepath) || (GLOBAL_VARS["prepath"] = prepath)

    # process configuration file (see also `process_mddefs!`)
    process_config()
    process_utils()

    # form page segments
    root       = path(:folder)
    layout     = path(:layout)

    head    = read(joinpath(layout, "head.html"),      String)
    pg_foot = read(joinpath(layout, "page_foot.html"), String)
    foot    = read(joinpath(layout, "foot.html"),      String)

    # look for an index file to process
    hasindexmd   = isfile(joinpath(root, "index.md"))
    hasindexhtml = isfile(joinpath(root, "index.html"))

    if !(hasindexmd || hasindexhtml)
        FD_ENV[:SOURCE] = "full pass"
        print_warning("""
            No 'index.md' or 'index.html' found in the root directory. There
            should be one. Ignoring.
            """)
    end

    # go over all pages note that the html files are processed AFTER the
    # markdown files and so if you both have an `index.md` and an `index.html`
    # with otherwise the same path, it's the latter that will be considered.
    s = 0
    for (case, dict) ∈ pairs(watched_files), (fpair, t) ∈ dict
        # help keep track of what we're doing for debugging
        (:fd_fullpass, joinpath(fpair...)) |> logger
        # process
        a = process_file(case, fpair, head, pg_foot, foot, t)
        # in case of failure of prerendering, if no_fail_prerender, we force
        # prerender=false
        if a < 0 && FD_ENV[:PRERENDER] && FD_ENV[:NO_FAIL_PRERENDER]
            FD_ENV[:PRERENDER] = false
            process_file(case, fpair, head, pg_foot, foot, t)
            FD_ENV[:PRERENDER]  = true
        end
        s += a
    end
    # re-evaluate delayed pages
    if !isempty(DELAYED)
        cp_DELAYED = copy(DELAYED)
        empty!(DELAYED) # so that functions are effectively applied
        for page in cp_DELAYED
            case = Symbol(strip(splitext(page)[2], '.'))
            fpair = path(:folder) => page
            a = process_file(case, fpair, head, pg_foot, foot)
            if a < 0 && FD_ENV[:PRERENDER] && FD_ENV[:NO_FAIL_PRERENDER]
                FD_ENV[:PRERENDER] = false
                process_file(case, fpair, head, pg_foot, foot)
                FD_ENV[:PRERENDER]  = true
            end
            s += a
        end
    end
    # generate RSS if appropriate
    globvar("generate_rss") && rss_generator()
    # generate tags if appropriate
    generate_tag_pages()
    # done
    FD_ENV[:FULL_PASS] = false
    # return -1 if any page failed to build, 0 otherwise
    return ifelse(s < 0, -1, 0)
end

"""
$(SIGNATURES)

This is the function that is continuously run, checks if files have been
modified and if so, processes them. Every 30 cycles, it checks whether any file
was added or deleted and consequently updates the `watched_files`.
"""
function fd_loop(cycle_counter::Int, ::LiveServer.FileWatcher,
                 watched_files::NamedTuple
                 )::Nothing
    verb = FD_ENV[:VERB]
    # every 30 cycles (3 seconds), scan directory to check for new or deleted
    # files and update dicts accordingly
    if mod(cycle_counter, 30) == 0
        # 1) check if some files have been deleted; note that we don't do
        # anything, we just remove the file reference from the corresponding
        # dictionary.
        for d ∈ watched_files, (fpair, _) ∈ d
            fpath = joinpath(fpair...)
            if !isfile(fpath)
                delete!(d, fpair)
                rp = splitext(get_rpath(fpath))[1]
                haskey(ALL_PAGE_VARS, rp) && delete!(ALL_PAGE_VARS, rp)
            end
        end
        # 2) scan the input folder, if new files have been added then this will
        # update the dictionaries
        scan_input_dir!(watched_files..., verb; in_loop=true)
    else
        layout = path(:layout)
        # do a pass over the files, check if one has changed and if so trigger
        # the appropriate file processing mechanism
        for (case, dict) ∈ pairs(watched_files), (fpair, t) ∈ dict
            # check if there was a modification to the file
            fpath = joinpath(fpair...)
            cur_t = mtime(fpath)
            cur_t <= t && continue
            # if there was then the file has been modified and should be
            # re-processed + copied
            fmsg = rpad("→ file $(fpath[length(FOLDER_PATH[])+1:end]) was " *
                        "modified ", 30)
            verb && print(fmsg)
            dict[fpair] = cur_t

            # Reprocess utils.jl in Utils module
            process_utils()

            # if it's an infra_file trigger a fullpass as potentially
            # the whole website depends upon it (e.g. CSS)
            if haskey(watched_files[:infra], fpair)
                verb && println("→ full pass...")
                start = time()
                fd_fullpass(watched_files)
                if verb
                    print_final(rpad("✔ full pass...", 15), start)
                    println("")
                end

            # if it's a literate_file, check that it's included on some page
            # and if it is, then trigger build of that (or those) page(s)
            elseif haskey(watched_files[:literate], fpair)
                fmsg = fmsg * rpad("→ updating... ", 15)
                verb && print("\r" * fmsg)
                start = time()
                #
                literate_path = splitext(unixify(joinpath(fpair...)))[1]
                # retrieve head, foot etc
                head   = read(joinpath(layout, "head.html"),      String)
                pgfoot = read(joinpath(layout, "page_foot.html"), String)
                foot   = read(joinpath(layout, "foot.html"),      String)
                # process all md files that have `\literate` with something
                # that matches
                for mdfpair in keys(watched_files.md)
                    # read the content and look for `{...}` that may refer
                    # to that script.
                    content = read(joinpath(mdfpair...), String)
                    for m in eachmatch(r"\{(.*?)(\.jl)?\}", content)
                        if endswith(literate_path, m.captures[1])
                            process_file(:md, mdfpair, head, pgfoot, foot,
                                         cur_t)
                            # no need to look at further matches on that page
                            # since we've already triggered the page build
                            break
                        end
                    end
                end
                verb && print_final(fmsg, start)

            # for any other file, just call `process_file`
            else
                fmsg = fmsg * rpad("→ updating... ", 15)
                verb && print("\r" * fmsg)
                start = time()
                # retrieve head, foot etc
                head   = read(joinpath(layout, "head.html"),      String)
                pgfoot = read(joinpath(layout, "page_foot.html"), String)
                foot   = read(joinpath(layout, "foot.html"),      String)
                # then process
                process_file(case, fpair, head, pgfoot, foot, cur_t)
                verb && print_final(fmsg, start)
            end
        end
    end
    return nothing
end
