"""
    judoc(;single_pass, clear_out_dir, verb)

Take a directory that contains markdown files (possibly in subfolders), convert
all markdown files to html and reproduce the same structure to an output dir.

* `single_pass` compiles the whole thing once (no dir watching).
* `clear_out_dir` destroys what was previously in `out_dir` this can be useful
if file names have been changed etc to get rid of stale files.
* `verb` whether to display things
"""
function judoc(;single_pass=true, clear_out_dir=false, verb=true)

    ###
    # . setting up:
    # -- reading and storing the path variables
    # -- setting up the output directory (clear if `clear_out_dir`)
    ###
    set_paths!()
    prepare_output_dir(clear_out_dir)

    ###
    # . recovering the list of files in the input dir we care about
    # -- these are stored in dictionaries, the key is the full path,
    # the value is the time of last change (useful for continuous monitoring)
    ###
    md_files    = Dict{Pair{String, String}, Float64}()
    html_files  = Dict{Pair{String, String}, Float64}()
    other_files = Dict{Pair{String, String}, Float64}()
    infra_files = Dict{Pair{String, String}, Float64}()
    watched_files = [md_files, html_files, other_files, infra_files]
    watched_names = ["md", "html", "other", "infra"]
    watched = zip(watched_names, watched_files)

    scan_input_dir!(watched_files...)

    head, pg_foot, foot = "", "", ""
    # looking for an index file to process
    indexmd   = JD_PATHS[:in] => "index.md"
    indexhtml = JD_PATHS[:in] => "index.html"

    # function corresponding to a "full pass" where every file is considered
    jd_full() = begin
        def_GLOB_VARS()
        def_LOC_VARS()
        def_GLOB_LXDEFS()

        process_config()

        head    = read(JD_PATHS[:in_html] * "head.html", String)
        pg_foot = read(JD_PATHS[:in_html] * "page_foot.html", String)
        foot    = read(JD_PATHS[:in_html] * "foot.html", String)

        if isfile(joinpath(indexmd...))
            process_file("md", indexmd, clear_out_dir,
                         head, pg_foot, foot)
        elseif isfile(joinpath(indexhtml...))
            process_file("html", indexhtml, clear_out_dir)
        else
            @warn "I didn't find an index.[md|html], there should be one. Ignoring."
        end
        # looking at the rest of the files
        for (name, dict) ∈ watched, (fpair, t) ∈ dict
            process_file(name, fpair, clear_out_dir,
                         head, pg_foot, foot, t)
        end
    end

    ###
    # . main part
    # -- if `single_pass` then the files are processed only once before
    # terminating
    # -- if `!single_pass` then the directory is monitored for file
    # changes until the user interrupts the session.
    ###
    verb && print("Compiling the full folder once... ")
    # ---------------------------
    start = time()              #
    jd_full()                   #
    verb && time_it_took(start) #
    # ---------------------------
    # variables useful when using continuous_checking
    # could be set externally though not very important
    SLEEP = 0.1
    NCYCL = 20   # every NCYCL * SLEEP, directory is checked
    if !single_pass
        println("Watching input folder... press CTRL+C to stop...\n")
        # this will go on until interrupted by the user (see catch)
        cntr = 1
        try while true
    		# every NCYCL cycles, scan directory, update dictionaries
    		if mod(cntr, NCYCL) == 0
    			# 1) check if some files have been deleted
    			# note we don't do anything. we just remove from the dict.
    			# to get clean folder --> rerun the compile() from blank
                for d ∈ watched_files, (fpair, _) ∈ d
                    !isfile(joinpath(fpair...)) && delete!(d, fpair)
                end
                # 2) scan the input folder, if new files have been
                # added then this will update the dictionaries
                scan_input_dir!(watched_files..., verb)
    			cntr = 1
    		else
                for (name, dict) ∈ watched, (fpair, t) ∈ dict
                    fpath = joinpath(fpair...)
                    cur_t = last(fpath)
                    cur_t <= t && continue
                    # if the time of last modification is
                    # greater (more recent) than the one stored in
                    # the dict then it means the file has been
                    # modified and should be re-processed + copied
                    verb && print("file $fpath was modified... ")
                    dict[fpair] = cur_t
                    if haskey(infra_files, fpair)
                        verb && print("\n... infra file modified --> full pass... ")
                        # ---------------------------
                        start = time()              #
                        jd_full()                   #
                        verb && time_it_took(start) #
                        # ---------------------------
                    else
                        # ----------------------------------------
                        start = time()                           #
                        process_file(name, fpair, false,         #
                                     head, pg_foot, foot, cur_t) #
                        verb && time_it_took(start)              #
                        # ----------------------------------------
                    end
                end
                # increase the loop counter
    			cntr += 1
    			sleep(SLEEP)
    		end # if mod(cntr, NCYCL)
            end # try while (same level as above, that's fine)
        catch x
        	if isa(x, InterruptException)
                println("\nShutting down JuDoc. ✅")
                return 0
            else
                println("An error caused JuDoc to stop, this is usually caused by bad syntax used somewhere such as braces not properly closed. Check. The error message is printed below.\n\n")
                println(x.msg)
                # rem we don't fail by rethrowing otherwise the corresponding
                # node process (browser-sync) doesn't get killed properly.
                return -1
            end
        end
    end # end if !single_pass
    return 0
end


"""
    run(; clear, verb,  port)

Runs JuDoc in a given directory. The named argument `clear` indicates whether
to clear the output dir or not, `verb` whether to display information about
changes etc seen by the engine, `port` where to serve with browser-sync.
"""
function serve(;clear=true, verb=false, port=8000)
    FOLDER_PATH[] = pwd()
    # next line is such that when called from outside using
    # `julia -e "using JuDoc; JuDoc.run()"` it interrupts nicely upon CTRL+C
    ccall(:jl_exit_on_sigint, Nothing, (Cint,), 0)
    # start browser-sync, serving in 8000
    run(`bash -c "browser-sync start -s -f $FOLDER_PATH --no-notify --logLevel silent --port $port &"`)
    println("Serving at localhost:$port...")
    println("Starting the engine (give it 1-2s)...")
    JuDoc.judoc(single_pass=false, verb=verb, clear_out_dir=clear);
end

const PY_MIN = raw"""
    import os
    from css_html_js_minify import process_single_html_file as min_html
    from css_html_js_minify import process_single_css_file as min_css
    # modify those if you're not using the standard output paths.
    CSS, PUB = "css/", "pub/"
    min_html("index.html", overwrite=True)
    for root, dirs, files in os.walk(PUB):
        for fname in files:
            if fname.endswith(".html"):
                min_html(os.path.join(root, fname), overwrite=True)

    for root, dirs, files in os.walk(CSS):
        for fname in files:
            if fname.endswith(".css"):
                min_css(os.path.join(root, fname), overwrite=True)
    """
const PY_MIN_NAME = ".__py_tmp_minscript.py"


function publish(; minify=true, push=true)
    if minify
        try
            print("Minifying .html and .css files...")
            write(PY_MIN_NAME, PY_MIN)
            run(`bash -c "python $PY_MIN_NAME > /dev/null"`)
            rm(PY_MIN_NAME)
            println(" [done] ✅")
        catch e
            println("\nCould not minify. Verify that you have css-html-js-minify installed (via pip) and that you use python 3.6+. Ignoring for now...\n")
            @show e
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
