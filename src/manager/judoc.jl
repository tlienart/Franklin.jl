"""
$(SIGNATURES)

Runs JuDoc in the current directory.

Keyword arguments:

* `clear=false`:     whether to remove any existing output directory
* `verb=false`:      whether to display messages
* `port=8000`:       the port to use for the local server (should pick a number between 8000 and 9000)
* `single=false`:    whether to run a single pass or run continuously
* `prerender=false`: whether to pre-render javascript (KaTeX and highlight.js)
"""
function serve(; clear::Bool=true, verb::Bool=false, port::Int=8000, single::Bool=false,
                 prerender::Bool=false)::Union{Nothing,Int}
    # set the global path
    JD_FOLDER_PATH[] = pwd()
    # construct the set of files to watch
    watched_files = jd_setup(clear=clear)

    # do a first full pass
    println("→ Initial full pass... ")
    start = time()
    sig = jd_fullpass(watched_files; clear=clear, verb=verb, prerender=prerender)
    sig < 0 && return sig
    verb && (print(rpad("\n✔ full pass...", 40)); time_it_took(start); println(""))

    # start the continuous loop
    if !single
        println("→ Starting the server...")
        coreloopfun = (cntr, fw) -> jd_loop(cntr, fw, watched_files; clear=clear, verb=verb)
        # start the liveserver in the current directory
        LiveServer.setverbose(verb)
        LiveServer.serve(port=port, coreloopfun=coreloopfun)
    end
    return nothing
end


"""
$(SIGNATURES)

Sets up the collection of watched files by doing an initial scan of the input directory.
It also sets the paths variables and prepares the output directory.

**Keyword argument**

* `clear=false`: whether to remove any existing output directory

See also [`serve`](@ref).
"""
function jd_setup(; clear::Bool=true)::NamedTuple
    # . setting up:
    # -- reading and storing the path variables
    # -- setting up the output directory (see `clear`)
    set_paths!()
    prepare_output_dir(clear)

    # . recovering the list of files in the input dir we care about
    # -- these are stored in dictionaries, the key is the full path and the value is the time of
    # last change (useful for continuous monitoring)
    md_files    = JD_FILES_DICT()
    html_files  = JD_FILES_DICT()
    other_files = JD_FILES_DICT()
    infra_files = JD_FILES_DICT()
    # named tuples of all the watched files
    watched_files = (md=md_files, html=html_files, other=other_files, infra=infra_files)
    # fill the dictionaries
    scan_input_dir!(watched_files...)
    return watched_files
end


"""
$(SIGNATURES)

A single full pass of judoc looking at all watched files and processing them as appropriate.

**Keyword arguments**

* `clear=false`:     whether to remove any existing output directory
* `verb=false`:      whether to display messages
* `prerender=false`: whether to prerender katex and code blocks

See also [`jd_loop`](@ref), [`serve`](@ref) and [`publish`](@ref).
"""
function jd_fullpass(watched_files::NamedTuple; clear::Bool=false, verb::Bool=false,
                     prerender::Bool=false)::Int
     # initiate page segments
     head    = read(joinpath(JD_PATHS[:in_html], "head.html"), String)
     pg_foot = read(joinpath(JD_PATHS[:in_html], "page_foot.html"), String)
     foot    = read(joinpath(JD_PATHS[:in_html], "foot.html"), String)

    # reset page variables and latex definitions
    def_GLOB_VARS!()
    def_LOC_VARS!()
    def_GLOB_LXDEFS!()

    # process configuration file
    process_config()

    # looking for an index file to process
    indexmd   = JD_PATHS[:in] => "index.md"
    indexhtml = JD_PATHS[:in] => "index.html"

    # rest of the pages, done asynchronously
    tasks = Vector{Task}()
    @sync begin
        if isfile(joinpath(indexmd...))
            push!(tasks, @async process_file(:md, indexmd, head, pg_foot, foot; clear=clear,
                                             prerender=prerender))
        elseif isfile(joinpath(indexhtml...))
            push!(tasks, @async process_file(:html, indexhtml, head, pg_foot, foot; clear=clear,
                                             prerender=prerender))
        else
            @warn "I didn't find an index.[md|html], there should be one. Ignoring."
        end
        # process rest of the files
        for (case, dict) ∈ pairs(watched_files), (fpair, t) ∈ dict
            occursin("index.", fpair.second) && continue
            sleep(0.001)
            push!(tasks, @async process_file(case, fpair, head, pg_foot, foot, t; clear=clear,
                                             prerender=prerender))
        end
    end
    # return -1 if any task has failed
    return -Int(any(t->t.result < 0, tasks))
end


"""
$(SIGNATURES)

This is the function that is continuously run, checks if files have been modified and if so,
processes them. Every 30 cycles, it checks whether any file was added or deleted and consequently
updates the `watched_files`.

**Keyword arguments**

* `clear=false`: whether to remove any existing output directory
* `verb=false`:  whether to display messages
"""
function jd_loop(cycle_counter::Int, ::LiveServer.FileWatcher, watched_files::NamedTuple;
                 clear::Bool=false, verb::Bool=false)::Nothing
    # every 30 cycles (3 seconds), scan directory to check for new or deleted files and
    # update dicts accordingly
    if mod(cycle_counter, 30) == 0
        # 1) check if some files have been deleted; note that we don't do anything,
        # we just remove the file reference from the corresponding dictionary.
        for d ∈ watched_files, (fpair, _) ∈ d
            isfile(joinpath(fpair...)) || delete!(d, fpair)
        end
        # 2) scan the input folder, if new files have been added then this will update
        # the dictionaries
        scan_input_dir!(watched_files..., verb)
    else
        # do a pass over the files, check if one has changed and if so trigger
        # the appropriate file processing mechanism
        for (case, dict) ∈ pairs(watched_files), (fpair, t) ∈ dict
            # check if there was a modification to the file
            fpath = joinpath(fpair...)
            cur_t = mtime(fpath)
            cur_t <= t && continue
            # if there was then the file has been modified and should be re-processed + copied
            verb && print(rpad("→ file $(fpath[length(JD_FOLDER_PATH[])+1:end]) was modified ", 30))
            dict[fpair] = cur_t
            # if it's an infra_file
            if haskey(watched_files[:infra], fpair)
                verb && println("→ full pass...")
                start = time()
                jd_fullpass(watched_files; clear=false, verb=false, prerender=false)
                verb && (print(rpad("\n✔ full pass...", 15)); time_it_took(start); println(""))
            else
                verb && print(rpad("→ updating... ", 15))
                start = time()
                # TODO, ideally these would only be read if they've changed. Not super important
                # but just not necessary. (Fixing may be a bit of a pain though)
                head    = read(joinpath(JD_PATHS[:in_html], "head.html"), String)
                pg_foot = read(joinpath(JD_PATHS[:in_html], "page_foot.html"), String)
                foot    = read(joinpath(JD_PATHS[:in_html], "foot.html"), String)
                process_file(case, fpair, head, pg_foot, foot, cur_t; clear=false, prerender=false)
                verb && time_it_took(start)
            end
        end
    end
    return nothing
end
