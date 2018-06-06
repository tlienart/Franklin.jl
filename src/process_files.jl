@static if VERSION < v"0.7.0-DEV.2005"
    using Base.Markdown: html
else
    using Markdown: html
end


"""
    convert_md!(jd_vars, md_string)

Take a raw MD string, process (and put away) the blocks, then parse the rest
using the default html parser. Finally, plug back in the processed content that
was put away and return the corresponding HTML string.
The dictionary `jd_vars` containing the document and/or the page variables is
updated once the local definitions have been read (see `jd_vars.jl`)
"""
function convert_md!(jd_vars, md_string)
    # -- Comments
    md_string = remove_comments(md_string)

    # -- Variables
    (md_string, defs) = extract_page_defs(md_string)
    set_vars!(jd_vars, defs)

    # -- Maths & Div blocks --
    (md_string, asym_bm) = asym_math_blocks(md_string)
    (md_string, sym_bm) = sym_math_blocks(md_string)
    (md_string, div_b) = div_blocks(md_string)

    # -- Standard Markdown parsing --
    html_string = html(Markdown.parse(md_string))

    # -- MATHS & DIV REPLACES --
    html_string = process_math_blocks(html_string, asym_bm, sym_bm)
    html_string = process_div_blocks(html_string, div_b)

    return html_string
end


"""
    prepare_output_dir(clear_out_dir)

Prepare the output directory `JD_PATHS[:out]`.

* `clear_out_dir` removes the content of the output directory if it exists to
start from a blank slate
"""
function prepare_output_dir(clear_out_dir=true)
    # read path variables from Main environment (see JuDoc.jl)
    set_paths!()

    # if required to start from a blank slate, we remove everything in
    # the output dir
    if clear_out_dir && isdir(JD_PATHS[:out])
        rm(JD_PATHS[:out], recursive=true)
    elseif !isdir(JD_PATHS[:out])
        mkdir(JD_PATHS[:out])
    end

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
    convert_dir(single_pass, clear_out_dir)

Take a directory that contains markdown files (possibly in subfolders), convert
all markdown files to html and reproduce the same structure to an output dir.

* `single_pass` compiles the whole thing once (no dir watching).
* `clear_out_dir` destroys what was previously in `out_dir` this can be useful
if file names have been changed etc to get rid of stale files.
"""
function convert_dir(single_pass=true, clear_out_dir=true)

    prepare_output_dir()

    # read the config.md file if it is present
    config_path = joinpath(JD_PATHS[:in], "config.md")
    if isfile(config_path)
        convert_md!(JD_GLOB_VARS, readstring(config_path))
    else
        warn("I didn't find a config file. Ignoring.")
    end

    ###
    # 2. CONVERSION & WRITING FILES
    # -- finding the files
    # -- converting them if required
    # -- writing / copying them at right place
    ###

    head_html = readstring(JD_PATHS[:in_html] * "head.html")
    foot_html = readstring(JD_PATHS[:in_html] * "foot.html")
    foot_content_html = readstring(JD_PATHS[:in_html] * "foot_content.html")

    length_in_dir = length(JD_PATHS[:in])

    if single_pass
        for (root, _, files) ∈ walkdir(JD_PATHS[:in])
            for file ∈ files
                fname, fext = splitext(file)
                if fext == ".md" && fname != "config"
                    ###
                    # 1. read markdown into string
                    # 2. convert to html
                    # 3. add head / foot from template
                    # 4. write at appropriate place
                    ###
                    jd_vars = merge(JD_GLOB_VARS, copy(JD_LOC_VARS))
                    md_string = readstring(joinpath(root, file))
                    html_string = convert_md!(jd_vars, md_string)

                    web_html = process_braces_blocks(head_html, jd_vars)
                    web_html *= "<div class=content>\n"
                    web_html *= html_string
                    web_html *= process_braces_blocks(foot_content_html, jd_vars)
                    web_html *= "\n</div>" # content
                    web_html *= process_braces_blocks(foot_html, jd_vars)

                    f_out_name = fname * ".html"
                    f_out_path = JD_PATHS[:out] * root[length_in_dir+1:end] * "/"
                    if !ispath(f_out_path)
                        mkpath(f_out_path)
                    end

                    write(f_out_path * f_out_name, web_html)

                else
                    # copy at appropriate place
                    f_out_path = JD_PATHS[:out] * root[length_in_dir+1:end]
                    if !ispath(f_out_path)
                        mkpath(f_out_path)
                    end
                    cp(joinpath(root, file), joinpath(f_out_path, file),
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

                                web_html = process_braces_blocks(head_html, jd_vars)
                                web_html *= "<div class=content>\n"
                                web_html *= html_string
                                web_html *= process_braces_blocks(foot_content_html, jd_vars)
                                web_html *= "\n</div>" # content
                                web_html *= process_braces_blocks(foot_html, jd_vars)

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
