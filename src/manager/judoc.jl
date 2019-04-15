# """
#     judoc(;single_pass, clear_out_dir, verb)
#
# Take a directory that contains markdown files (possibly in subfolders), convert all markdown files
# to html and reproduce the same structure to an output dir.
#
# * `single_pass` compiles the whole thing once (no dir watching).
# * `clear_out_dir` destroys what was previously in `out_dir` this can be useful
# if file names have been changed etc to get rid of stale files.
# * `verb` whether to display things
# """

"""
    jd_setup(clear::Bool)

Sets up the collection of `watched_files` by doing an initial scan of the input directory.
It also sets the paths variables and prepares the output directory.
The `clear` argument indicates whether to remove any existing output directory or not.
"""
function jd_setup(clear::Bool=true)
    ###
    # . setting up:
    # -- reading and storing the path variables
    # -- setting up the output directory (clear if `clear_out_dir`)
    ###
    set_paths!()
    prepare_output_dir(clear)

    ###
    # . recovering the list of files in the input dir we care about
    # -- these are stored in dictionaries, the key is the full path,
    # the value is the time of last change (useful for continuous monitoring)
    ###
    md_files    = Dict{Pair{String, String}, Float64}()
    html_files  = Dict{Pair{String, String}, Float64}()
    other_files = Dict{Pair{String, String}, Float64}()
    infra_files = Dict{Pair{String, String}, Float64}()
    watched_files = (md=md_files, html=html_files, other=other_files, infra=infra_files)
    scan_input_dir!(watched_files...)

    return watched_files
end

"""
    jd_fullpass(watched_files::NamedTuple, clear::Bool)

A single full pass of judoc looking at all watched files and processing them as appropriate.
"""
function jd_fullpass(watched_files::NamedTuple, clear::Bool; prerender::Bool=false)
     # initiate page segments
     head    = read(joinpath(JD_PATHS[:in_html], "head.html"), String)
     pg_foot = read(joinpath(JD_PATHS[:in_html], "page_foot.html"), String)
     foot    = read(joinpath(JD_PATHS[:in_html], "foot.html"), String)

    # reset page variables and latex definitions
    def_GLOB_VARS(; prerender=prerender)
    def_LOC_VARS()
    def_GLOB_LXDEFS()

    # process configuration file
    process_config()

    # looking for an index file to process
    indexmd   = JD_PATHS[:in] => "index.md"
    indexhtml = JD_PATHS[:in] => "index.html"

    # the process_file may error
    try
        if isfile(joinpath(indexmd...))
            process_file(:md, indexmd, clear, head, pg_foot, foot)
        elseif isfile(joinpath(indexhtml...))
            # there is a file `index.html`, process it
            process_file(:html, indexhtml, clear)
        else
            @warn "I didn't find an index.[md|html], there should be one. Ignoring."
        end
        # look at the rest of the files
        for (case, dict) ∈ pairs(watched_files), (fpair, t) ∈ dict
            process_file(case, fpair, clear, head, pg_foot, foot, t)
        end
    catch err
        if isa(err, ErrorException)
            # Will be a JuDoc error (e.g. variable does not exist or brackets not
            # closed etc, mainly parsing errors). See also process_file
            return -1 # caught in `file_utils/process_file`
        else
            # this is unlikely
            println("An unexpected error caused JuDoc to stop. Check.")
            println("The error message is printed below.\n\n")
            @show err
            return -2
        end
    end
    return 0
end

"""
    jd_loop(cycle_counter, filewatcher, clear, watched_files, verb)

This is the function that is continuously run, checks if files have been modified and if so,
processes them. Every 30 cycles, it checks whether any file was added or deleted and consequently
updates the `watched_files`.
"""
function jd_loop(cycle_counter::Int, ::LiveServer.FileWatcher, clear::Bool,
                 watched_files::NamedTuple, verb::Bool;
                 prerender::Bool=false)
    # every 50 cycles (5 seconds), scan directory to check for new or deleted files and
    # update dicts accordingly
    if mod(cycle_counter, 30) == 0
        # 1) check if some files have been deleted; note that we don't do anything,
        # we just remove the file reference from the corresponding dictionary.
        # NOTE watched.is[2] is watched_files, see jd_setup
        for d ∈ watched_files, (fpair, _) ∈ d
            isfile(joinpath(fpair...)) || delete!(d, fpair)
        end
        # 2) scan the input folder, if new files have been
        # added then this will update the dictionaries
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
            verb && print("file $fpath was modified... ")
            dict[fpair] = cur_t
            # if it's an infra_file
            if haskey(watched_files[:infra], fpair)
                verb && print("\n... infra file modified --> full pass... ")
                start = time()
                jd_fullpass(watched_files, false; prerender=prerender)
                verb && time_it_took(start)
            else
                start = time()
                # TODO, ideally these would only be read if they've changed. Not super important
                # but just not necessary. (Fixing may be a bit of a pain though)
                head    = read(joinpath(JD_PATHS[:in_html], "head.html"), String)
                pg_foot = read(joinpath(JD_PATHS[:in_html], "page_foot.html"), String)
                foot    = read(joinpath(JD_PATHS[:in_html], "foot.html"), String)
                process_file(case, fpair, false, head, pg_foot, foot, cur_t) #
                verb && time_it_took(start)
            end
        end
    end
    return nothing
end

"""
    serve(; clear, verb,  port)

Runs JuDoc in the current directory. The named argument `clear` indicates whether to clear the
output dir or not, `verb` whether to display information about changes etc seen by the engine,
`port` where to serve with LiveServer.
"""
function serve(; clear::Bool=true,
                 verb::Bool=false,
                 port::Int=8000,
                 single::Bool=false,
                 prerender::Bool=false)

    JD_FOLDER_PATH[] = pwd()

    if prerender && !JD_HAS_NODE
        @warn "I couldn't find node and so will not be able to pre-render javascript."
        prerender = false
    end

    # set things up
    # -------------
    watched_files = jd_setup(clear)

    # do a first pass
    # ---------------
    print("→ Initial full pass... ")
    start = time()
    sig = jd_fullpass(watched_files, clear; prerender=prerender)
    sig < 0 && return sig
    time_it_took(start)

    # start the continuous loop
    # -------------------------
    println("→ Starting the server")
    if !single
        coreloopfun = (cntr, fw) -> jd_loop(cntr, fw, clear, watched_files, verb;
                                            prerender=prerender)
        # start the liveserver in the current directory
        LiveServer.setverbose(verb)
        LiveServer.serve(port=port, coreloopfun=coreloopfun)
    end
    return nothing
end

#
# MINIFY AND PUBLISH TO GITHUB
#

const JD_PY_MIN = read(joinpath(dirname(pathof(JuDoc)), "scripts", "minify.py"), String)

const JD_PY_MIN_NAME = ".__py_tmp_minscript.py"

function publish(; minify=true, push=true)
    if minify
        if !JD_HAS_MINIFY
            @warn "I didn't find css_html_js_minify, you can install it via pip the output will "*
                  "not be minified"
        else
            print("Minifying .html and .css files...")
            write(JD_PY_MIN_NAME, JD_PY_MIN)
            run(`bash -c "python $JD_PY_MIN_NAME > /dev/null"`)
            rm(JD_PY_MIN_NAME)
            println(" [done] ✅")
        end
    end
    if push
        print("Pushing updates on Github...")
        try
            run(`bash -c "git add -A && git commit -m \"jd-update\" --quiet && git push --quiet"`, wait=true)
            println(" [done] ✅")
        catch e
            println("Could not push updates to Github, verify your connection and try manually.\n")
        end
    end
end


function cleanpull()
    JD_FOLDER_PATH[] = pwd()
    set_paths!()
    if isdir(JD_PATHS[:out])
        print("Removing local output dir...")
        rm(JD_PATHS[:out], force=true, recursive=true)
        println(" [done] ✅")
    end
    try
        print("Retrieving updates from GitHub...")
        run(`bash -c "git pull --quiet"`, wait=true)
        println(" [done] ✅")
    catch e
        println("Could not pull updates from Github, verify your connection and try manually.\n")
    end
end
