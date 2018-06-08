@static if VERSION < v"0.7.0-DEV.2005"
    using Base.Markdown: html
else
    using Markdown: html
end


"""
    prepare_output_dir(clear_out_dir)

Prepare the output directory `JD_PATHS[:out]`.

* `clear_out_dir` removes the content of the output directory if it exists to
start from a blank slate
"""
function prepare_output_dir(clear_out_dir=true)
    # if required to start from a blank slate, we remove everything in
    # the output dir
    if clear_out_dir && isdir(JD_PATHS[:out])
        rm(JD_PATHS[:out], recursive=true)
    end
    !isdir(JD_PATHS[:out]) && mkdir(JD_PATHS[:out])

    # check if the css and libs folder need to be added or not.
    # NOTE if processing CSS later, this may have to change
    if !isdir(JD_PATHS[:out_css])
        # copying template CSS files
        cp(JD_PATHS[:in_css], JD_PATHS[:out_css])
    end
    if !isdir(JD_PATHS[:out_libs])
        # copying libs
        cp(JD_PATHS[:in_libs], JD_PATHS[:out_libs])
    end
end


"""
    process_config()

Checks for a `config.md` file in `JD_PATHS[:in]` and uses it to set the global
variables referenced in `JD_GLOB_VARS`. If the configuration file is not found
a warning is shown.
"""
function process_config()
    # read the config.md file if it is present
    config_path = joinpath(JD_PATHS[:in], "config.md")
    if isfile(config_path)
        _, config_defs = convert_md(readstring(config_path))
        set_vars!(JD_GLOB_VARS, config_defs)
    else
        warn("I didn't find a config file. Ignoring.")
    end
end


"""
    out_path(root)

Take a `root` path to an input file and convert to output path. If the output
path does not exist, create it.
"""
function out_path(root)
    f_out_path = JD_PATHS[:out] * root[length(JD_PATHS[:in])+1:end]
    !ispath(f_out_path) && mkpath(f_out_path)
    return f_out_path
end


"""
    convert_md(md_string)

Take a raw MD string, process (and put away) the blocks, then parse the rest
using the default html parser. Finally, plug back in the processed content that
was put away and return the corresponding HTML string.
Definitions present in the `md_string` are extracted and returned for further
processing.
"""
function convert_md(md_string)
    # Comments and variables
    md_string = remove_comments(md_string)
    (md_string, defs) = extract_page_defs(md_string)

    # Maths & Div blocks
    (md_string, asym_bm) = asym_math_blocks(md_string)
    (md_string, sym_bm) = sym_math_blocks(md_string)
    (md_string, div_b) = div_blocks(md_string)

    # Standard Markdown parsing on the rest
    html_string = html(Markdown.parse(md_string))

    # Process blocks and plug back in what is needed
    html_string = process_math_blocks(html_string, asym_bm, sym_bm)
    html_string = process_div_blocks(html_string, div_b)

    return (html_string, defs)
end


"""
    write_page(root, file, head, pg_foot, foot)

Take a path to an input markdown file (via `root` and `file`), then construct
the appropriate HTML page (inserting `head`, `pg_foot` and `foot`) and
finally write it at the appropriate place.
"""
function write_page(root, file, head, pg_foot, foot)
    ###
    # 0. create a dictionary with all the variables available to the page
    # 1. read the markdown into string, convert it and extract definitions
    # 2. eval the definitions and update the variable dictionary
    ###
    jd_vars = merge(JD_GLOB_VARS, copy(JD_LOC_VARS))
    (content, defs) = convert_md(readstring(joinpath(root, file)))
    set_vars!(jd_vars, defs)
    ###
    # 3. process blocks in the html infra elements based on `jd_vars` (e.g.:
    # add the date in the footer)
    ###
    head, pg_foot, foot = (process_html_blocks(e, jd_vars)
                                for e ∈ [head, pg_foot, foot])
    ###
    # 4. construct the page proper
    ###
    pg = head * "<div class=content>\n" * content * pg_foot * "</div>" * foot
    ###
    # 5. write the html file where appropriate
    ###
    write(out_path(root) * change_ext(file), pg)
end


"""
    scan_input_dir!(md_files, html_files, other_files)

Update the dictionaries referring to input files and their time of last
change.
"""
function scan_input_dir!(md_files, html_files, other_files, verb=false)
    for (root, _, files) ∈ walkdir(JD_PATHS[:in])
        # ensure there's a "/" at the end of the path
        nroot = normpath(root * "/")
        # skip if the root leads to a passive dir
        any(contains(nroot, dir) for dir ∈ PASSIVE_DIRS) && continue
        for file ∈ files
            # skip if it's the config file
            file ∈ IGNORE_FILES && continue
            fname, fext = splitext(file)
            fpair = nroot=>file
            if fext == ".md"
                add_if_new_file!(md_files, fpair, verb)
            elseif fext == ".html"
                add_if_new_file!(html_files, fpair, verb)
            else
                add_if_new_file!(other_files, fpair, verb)
            end
        end
    end
end


"""
    convert_dir(single_pass, clear_out_dir)

Take a directory that contains markdown files (possibly in subfolders), convert
all markdown files to html and reproduce the same structure to an output dir.

* `single_pass` compiles the whole thing once (no dir watching).
* `clear_out_dir` destroys what was previously in `out_dir` this can be useful
if file names have been changed etc to get rid of stale files.
"""
function convert_dir(;single_pass=true, clear_out_dir=true, verb=true)

    ###
    # . setting up:
    # -- reading and storing the path variables
    # -- setting up the output directory (potentially erasing it if
    # `clear_out_dir`)
    # -- read the configuration file
    ###

    set_paths!()
    prepare_output_dir(clear_out_dir)
    process_config()

    # variables useful when using continuous_checking
    # TODO this could be set externally (e.g. in config file)
    START = time()
    MAXT = 5000 # max number of seconds before shutting down.
    SLEEP = 0.1
    NCYCL = 20

    ###
    # . recovering the list of files in the input dir we care about
    # -- these are stored in dictionaries, the key is the full path,
    # the value is the time of last change (useful for continuous
    # monitoring)
    ###

    md_files = Dict{Pair{String, String}, UInt}()
    html_files = other_files = similar(md_files)
    watched_files = [md_files, html_files, other_files]
    watched_names = ["md", "html", "other"]
    watched = zip(watched_names, watched_files)

    scan_input_dir!(watched_files...)

    ###
    # . finding and reading the infrastructure files (used in write_page)
    ###

    head = readstring(JD_PATHS[:in_html] * "head.html")
    pg_foot = readstring(JD_PATHS[:in_html] * "page_foot.html")
    foot = readstring(JD_PATHS[:in_html] * "foot.html")

    ###
    # . main part
    # -- if `single_pass` then the files are processed only once before
    # terminating
    # -- if `!single_pass` then the directory is monitored for file
    # changes until the user interrupts the session.
    ###

    verb && print("Compiling the full folder once... ")
    start = time()
    for (name, dict) ∈ watched, (fpair, t) ∈ dict
        if name == "md"
            # fpair.first = root path; fpair.second = fname
            write_page(fpair..., head, pg_foot, foot)
        elseif name == "html"
            raw_html = readstring(joinpath(fpair...))
            proc_html = process_html_blocks(raw_html, JD_GLOB_VARS)
            @show out_path(fpair.first) * fpair.second
            write(out_path(fpair.first) * fpair.second, proc_html)
        else # name == "other"
            opath = out_path(fpair.first) * fpair.second
            # only copy it again if necessary (particularly relevant)
            # when the asset files take quite a bit of space.
            if clear_out_dir || !isfile(opath) || last(opath) < t
                cp(joinpath(fpair...), opath, remove_destination=true)
            end
        end
    end
    verb && time_it_took(start)

    if !single_pass
        println("Watching input folder... press CTRL+C to stop.")
        # this will go on until interrupted by the user (see catch)
        cntr = 1
        try while true
    		# every NCYCL cycles, scan directory, update dictionaries
    		if mod(cntr, NCYCL) == 0
    			# 1 check if some files have been deleted
    			# note we don't do anything. we just remove from the dict.
    			# to get clean folder --> rerun the compile() from blank
                for d ∈ watched_files, (fpair, _) ∈ d
                    !isfile(joinpath(fpair...)) && delete!(d, fpair)
                end
                # 2 scan the input folder, if new files have been
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
                    start = time()
                    dict[fpair] = cur_t
                    if name == "md"
                        write_page(fpair..., head, pg_foot, foot)
                    elseif name =="html"
                        raw_html = readstring(fpath)
                        proc_html = process_html_blocks(raw_html, JD_GLOB_VARS)
                        write(out_path(fpair.first) * fpair.second, proc_html)
                    else # name == "other"
                        cp(fpath, out_path(fpair.first) * fpair.second, remove_destination=true)
                    end
                    verb && time_it_took(start)
                end
                # increase the loop counter
    			cntr += 1
    			sleep(SLEEP)
    		end # if mod(cntr, NCYCL)
            end # try while
        catch x
        	isa(x, InterruptException) ? println("Shutting down.") : throw(x)
        end
    end
end


#=
    Helper functions

Small functions defined to de-clutter the code of `convert_dir`.
=#


"""
    add_if_new_file!(dict, fpair)

Helper function, if `fpair` is not referenced in the dictionary (new file)
add the entry to the dictionary with the time of last modification as val.
"""
function add_if_new_file!(dict, fpair, verb)
    if !haskey(dict, fpair)
        verb && println("tracking new file '$(fpair.second)'.")
        dict[fpair] = last(joinpath(fpair...))
    end
end


"""
    last(f)

Convenience function to get the time of last modification of a file.
"""
last(f::String) = stat(f).mtime


"""
    time_it_took(start)

Convenience function to display a time since `start`.
"""
function time_it_took(start)
    comp_time = time() - start
    mess = comp_time > 60 ? "$(round(comp_time/60, 1))m" :
           comp_time > 1 ? "$(round(comp_time, 1))s" :
           "$(round(comp_time*1000, 1))μs"
    println("[done $mess]")
end
