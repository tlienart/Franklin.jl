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
    elseif !isdir(JD_PATHS[:out])
        mkdir(JD_PATHS[:out])
    end

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
    !ispath(f_out_path) ? mkpath(f_out_path) : nothing
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
    write(out_path(root) * basename(file) * ".html", pg)
end


"""
    convert_dir(single_pass, clear_out_dir)

Take a directory that contains markdown files (possibly in subfolders), convert
all markdown files to html and reproduce the same structure to an output dir.

* `single_pass` compiles the whole thing once (no dir watching).
* `clear_out_dir` destroys what was previously in `out_dir` this can be useful
if file names have been changed etc to get rid of stale files.
"""
function convert_dir(single_pass=true, clear_out_dir=true)

    set_paths!()
    prepare_output_dir()
    process_config()

    ###
    # 1. finding and reading the infrastructure files now that paths are set
    ###
    head = readstring(JD_PATHS[:in_html] * "head.html")
    page_foot = readstring(JD_PATHS[:in_html] * "page_foot.html")
    foot = readstring(JD_PATHS[:in_html] * "foot.html")

    if single_pass
        for (root, _, files) ∈ walkdir(JD_PATHS[:in])
            for file ∈ files
                fname, fext = splitext(file)
                if fext == ".md" && fname != "config"
                    write_page(root, file, head, page_foot, foot)
                elseif fext == ".html"
                    raw_html = readstring(joinpath(root, file))
                    proc_html = process_html_blocks(raw_html, JD_GLOB_VARS)
                    write(out_path(root) * file, proc_html)
                else
                    # copy file at appropriate place
                    cp(joinpath(root, file), out_path(root) * file,
                        remove_destination=true)
                end
            end
        end # walkdir
    else
        # NOTE: experimental multiple pass.
        # Should probably go in external function
        # 1. Should probably go through a normal single pass
        # 2. Continuously look at EXT files
        # NOTE
        #  - TODO: what about new assets that get added? should be copied over
        #  - TODO: if infra files get modif (_html/*), all files need rewrite

        println("Warming up, compiling the folder once...")
        convert_dir(true, clear_out_dir)

        watched_files = Dict{String, UInt}()
        other_files = Dict{String, UInt}()
        for (root, _, files) ∈ walkdir(JD_PATHS[:in])
        	for file ∈ files
                f = joinpath(root, file)
                if splitext(file)[2] == ".md"
            		watched_files[f] = stat(f).mtime
                else
                    other_files[f] = stat(f).mtime
                end
        	end
        end

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
        			# note we don't do anything. we just remove from the list.
        			# to get clean folder --> rerun the compile()
        			for (f, _) ∈ watched_files
        				if !isfile(f)
        					delete!(watched_files, f)
        				end
        			end
                    for (f, _) ∈ other_files
                        if !isfile(f)
                            delete!(other_files, f)
                        end
                    end
        			# 2 check if some files have been added
        			for (root, _, files) ∈ walkdir(JD_PATHS[:in])
        				for file ∈ files
                            f = joinpath(root, file)
                            if splitext(file)[2] == ".md"
            					if !haskey(watched_files, f)
            						watched_files[f] = stat(f).mtime
            					end
                            else
                                if !haskey(other_files, f)
                                    other_files[f] = stat(f).mtime
                                end
                            end
        				end
        			end
        			cntr = 1
                # ---------------
                # THE NORMAL LOOP
        		else
        			for (f, t) ∈ watched_files
        				cur_t = stat(f).mtime
        				if cur_t > t
        					watched_files[f] = cur_t
                            # HERE ARE MODIFIED MD FILES
                            if f == CONFIG
                                convert_md!(JD_GLOB_VARS, readstring(CONFIG))
                            else
                                jd_vars = merge(JD_GLOB_VARS, copy(JD_LOC_VARS))
                                md_string = readstring(f)
                                html_string = convert_md!(jd_vars, md_string)

                                web_html = process_html_blocks(head_html, jd_vars)
                                web_html *= "<div class=content>\n"
                                web_html *= html_string
                                web_html *= process_html_blocks(page_foot, jd_vars)
                                web_html *= "\n</div>" # content
                                web_html *= process_html_blocks(foot_html, jd_vars)

                                f_out_name = splitext(basename(f))[1] * ".html"
                                f_out_path = JD_PATHS[:out] * dirname(f)[length_in_dir+1:end] * "/"
                                if !ispath(f_out_path)
                                    mkpath(f_out_path)
                                end

                                write(f_out_path * f_out_name, web_html)
                            end
        				end
        			end
                    for (f, t) ∈ other_files
                        cur_t = stat(f).mtime
                        if cur_t > t
                            other_files[f] = cur_t
                            # HERE ARE MODIFIED NON-MD FILES
                            # COPY NEW FILE, OVERWRITE DESTINATION
                            f_out_path = JD_PATHS[:out] * dirname(f)[length_in_dir+1:end]
                            if !ispath(f_out_path)
                                mkpath(f_out_path)
                            end
                            cp(f, joinpath(f_out_path, basename(f)),
                                remove_destination=true)
                        end
                    end
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
