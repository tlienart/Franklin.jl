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
    write_page(root, file, head, page_foot, foot)

Take a path to an input markdown file (via `root` and `file`), then construct
the appropriate HTML page (inserting `head`, `page_foot` and `foot`) and
finally write it at the appropriate place.
"""
function write_page(root, file, head, page_foot, foot)
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
    head, page_foot, foot = (process_html_blocks(e, jd_vars)
                                for e ∈ [head, page_foot, foot])
    ###
    # 4. construct the page proper
    ###
    pg = head * "<div class=content>\n" * content * page_foot * "</div>" * foot
    ###
    # 5. write the html file where appropriate
    ###
    write(out_path(root) * change_ext(file), pg)
end


"""
    convert_dir(single_pass, clear_out_dir)

Take a directory that contains markdown files (possibly in subfolders), convert
all markdown files to html and reproduce the same structure to an output dir.

* `single_pass` compiles the whole thing once (no dir watching).
* `clear_out_dir` destroys what was previously in `out_dir` this can be useful
if file names have been changed etc to get rid of stale files.
"""
function convert_dir(;single_pass=true, clear_out_dir=true)

    set_paths!()
    prepare_output_dir(clear_out_dir)
    process_config()

    ###
    # 0. recovering the list of files in the input dir we actually care about
    # -- we store these in dictionaries, the key is the full path, the value
    # is the time of last change (useful for continuous monitoring)
    ###

    IGNORE_DIRS = [JD_PATHS[i] for i ∈ [:in_libs, :in_css, :in_html]]

    md_files = Dict{Pair{String, String}, UInt}()
    html_files = Dict{Pair{String, String}, UInt}()
    other_files = Dict{Pair{String, String}, UInt}()

    for (root, _, files) ∈ walkdir(JD_PATHS[:in])
        nroot = normpath(root * "/")
        if !any(contains(nroot, dir) for dir ∈ IGNORE_DIRS)
            for file ∈ files
                fname, fext = splitext(file)
                if fext == ".md"
                    if fname != "config"
                        md_files[nroot=>file] = stat(nroot * file).mtime
                    end
                elseif fext == ".html"
                    html_files[nroot=>file] = stat(nroot * file).mtime
                else
                    other_files[nroot=>file] = stat(nroot * file).mtime
                end
            end
        end
    end

    ###
    # 1. finding and reading the infrastructure files now that paths are set
    ###
    head = readstring(JD_PATHS[:in_html] * "head.html")
    page_foot = readstring(JD_PATHS[:in_html] * "page_foot.html")
    foot = readstring(JD_PATHS[:in_html] * "foot.html")

    if single_pass
        for (fpair, _) ∈ md_files
            # fpair.first = root path; fpair.second = fname
            write_page(fpair.first, fpair.second, head, page_foot, foot)
        end
        for (fpair, _) ∈ html_files
            raw_html = readstring(joinpath(fpair...))
            proc_html = process_html_blocks(raw_html, JD_GLOB_VARS)
            write(out_path(fpair.first) * fpair.second, proc_html)
        end
        for (fpair, t) ∈ other_files
            opath = out_path(fpair.first) * fpair.second
            if clear_out_dir || !isfile(opath) || stat(opath).mtime < t
                    cp(joinpath(fpair...), opath, remove_destination=true)
            end
        end
    else
        # NOTE: experimental multiple pass.
        # Should probably go in external function
        # 1. Should probably go through a normal single pass
        # 2. Continuously look at EXT files
        # NOTE
        #  - TODO: what about new assets that get added? should be copied over
        #  - TODO: if infra files get modif (_html/*), all files need rewrite

        println("Warming up, compiling the full folder once...")
        convert_dir(single_pass=true, clear_out_dir=false)

        watched_files = merge(md_files, html_files)

        # TODO set these constants somewhere else (config)
        START  = time()
        MAXT   = 5000 # max number of seconds before shutting down.
        SLEEP  = 0.1
        NCYCL  = 20
        CONFIG = joinpath(JD_PATHS[:in], "config.md")

        cntr = 1
        try
        	println("Watching input folder... press CTRL+C to stop.")
        	while true
                # ------------------
        		# every NCYCL cycles, check directory for potential new files
        		if mod(cntr, NCYCL) == 0
        			# 1 check if some files have been deleted
        			# note we don't do anything. we just remove from the dict.
        			# to get clean folder --> rerun the compile() from blank
                    for dict ∈ [md_files, html_files, other_files]
                        for (fpair, _) ∈ dict
                            !isfile(joinpath(fpair...)) && delete!(dict, fpair)
                        end
                    end
        			# 2 check if some files have been added
                    # if so, add them to relevant dictionary
        			for (root, _, files) ∈ walkdir(JD_PATHS[:in])
                        nroot = normpath(root * "/")
                        if !any(contains(nroot, dir) for dir ∈ IGNORE_DIRS)
                            for file ∈ files
                                fname, fext = splitext(file)
                                fpair = nroot=>file
                                if fext == ".md"
                                    if !haskey(md_files, fpair) && fname != "config"
                                        md_files[fpair] = stat(nroot * file).mtime
                                    end
                                elseif fext == ".html" && !haskey(html_files, fpair)
                                    html_files[fpair] = stat(nroot * file).mtime
                                elseif !haskey(other_files, fpair)
                                    other_files[fpair] = stat(nroot * file).mtime
                                end
                            end
                        end
        			end
        			cntr = 1
                # ---------------
                # THE NORMAL LOOP
        		else
                    for (fpair, t) ∈ md_files
                        cur_t = stat(joinpath(fpair...)).mtime
                        if cur_t > t
                            md_files[fpair] = cur_t
                            write_page(fpair.first, fpair.second, head, page_foot, foot)
                        end
                    end
                    for (fpair, t) ∈ html_files
                        cur_t = stat(joinpath(fpair...)).mtime
                        if cur_t > t
                            html_files[fpair] = cur_t
                            raw_html = readstring(joinpath(fpair...))
                            proc_html = process_html_blocks(raw_html, JD_GLOB_VARS)
                            write(out_path(fpair.first) * fpair.second, proc_html)
                        end
                    end
                    for (fpair, t) ∈ other_files
                        cur_t = stat(joinpath(fpair...)).mtime
                        if cur_t > t
                            other_files[fpair] = cur_t
                            cp(joinpath(fpair...), out_path(fpair.first) * fpair.second, remove_destination=true)
                        end
                    end
                    # increase the loop counter
        			cntr += 1
        			sleep(SLEEP)
        		end
        	end
        catch x
        	if isa(x, InterruptException)
        		println("Shutting down.")
        	else
        		throw(x)
        	end
        end
    end
end
