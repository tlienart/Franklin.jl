"""
    process_config()

Checks for a `config.md` file in `JD_PATHS[:in]` and uses it to set the global variables referenced
in `JD_GLOB_VARS` it also sets the global latex commands via `JD_GLOB_LXDEFS`. If the configuration
file is not found a warning is shown.
"""
function process_config()

    # read the config.md file if it is present
    config_path = joinpath(JD_PATHS[:in], "config.md")
    if isfile(config_path)
        convert_md(read(config_path, String) * EOS; isconfig=true)
    else
        @warn "I didn't find a config file. Ignoring."
    end

    if JD_GLOB_VARS["codetheme"][1] !== nothing
        path = joinpath(JD_PATHS[:out_css], "highlight.css")
        # NOTE: will overwrite (every time config.md is modified)
        isdir(JD_PATHS[:out_css]) || mkpath(JD_PATHS[:out_css])
        open(path, "w+") do stream
            stylesheet(stream, MIME("text/css"), JD_GLOB_VARS["codetheme"][1])
        end
    end

    return nothing
end


"""
    build_page(head, content, pg_foot, foot)

Convenience function to assemble the html out of its parts.
"""
build_page(head, content, pg_foot, foot) =
    "$head\n<div class=\"jd-content\">\n$content\n$pg_foot\n</div>\n$foot"


"""
    write_page(root, file, head, pg_foot, foot)

Take a path to an input markdown file (via `root` and `file`), then construct the appropriate HTML
page (inserting `head`, `pg_foot` and `foot`) and finally write it at the appropriate place.
"""
function write_page(root, file, head, pg_foot, foot)

    ###
    # 0. create a dictionary with all the variables available to the page
    # 1. read the markdown into string, convert it and extract definitions
    # 2. eval the definitions and update the variable dictionary, also retrieve
    # document variables (time of creation, time of last modif) and add those
    # to the dictionary.
    ###
    jd_vars = merge(JD_GLOB_VARS, copy(JD_LOC_VARS))
    fpath = joinpath(root, file)
    vJD_GLOB_LXDEFS = collect(values(JD_GLOB_LXDEFS))
    (content, jd_vars) = convert_md(read(fpath, String) * EOS, vJD_GLOB_LXDEFS)

    # adding document variables to the dictionary
    s = stat(fpath)
    set_var!(jd_vars, "jd_ctime", jd_date(unix2datetime(s.ctime)))
    set_var!(jd_vars, "jd_mtime", jd_date(unix2datetime(s.mtime)))
    ###
    # 3. process blocks in the html infra elements based on `jd_vars` (e.g.:
    # add the date in the footer)
    ###
    content = convert_html(str(content), jd_vars)
    head, pg_foot, foot = (e->convert_html(e, jd_vars)).([head, pg_foot, foot])

    ###
    # 4. construct the page proper
    ###
    pg = build_page(head, content, pg_foot, foot)
    ###
    # 5. write the html file where appropriate
    ###
    write(joinpath(out_path(root), change_ext(file)), pg)

    return nothing
end


function process_file(case, fpair, args...)

    try
        process_file_err(case, fpair, args...)
    catch err
        rp = fpair.first
        rp = rp[end-min(20, length(rp))+1 : end]
        println("\n... error processing '$(fpair.second)' in ...$rp.\n Verify, then start judoc again...\n")
        @show err
        cleanup_process()
        throw(ErrorException("jd-err"))
    end

    return
end


"""
    proces_file_err(case, fpair, clear_out_dir, head, pg_foot, foot, t)

Considers a source file which, depending on `case` could be a html file or a file in judoc markdown
etc, located in a place described by `fpair`, processes it by converting it and adding appropriate
header and footer and writes it to the appropriate place. It can throw an error which will be
caught in `process_file(args...)`.
"""
function process_file_err(case, fpair, clear_out_dir,
                          head="", pg_foot="", foot="", t=0.)

    if case == "md"
        write_page(fpair..., head, pg_foot, foot)
    elseif case == "html"
        raw_html = read(joinpath(fpair...), String)
        proc_html = convert_html(raw_html, JD_GLOB_VARS)
        write(joinpath(out_path(fpair.first), fpair.second), proc_html)
    elseif case == "other"
        opath = joinpath(out_path(fpair.first), fpair.second)
        # only copy it again if necessary (particularly relevant)
        # when the asset files take quite a bit of space.
        if clear_out_dir || !isfile(opath) || mtime(opath) < t
            cp(joinpath(fpair...), opath, force=true)
        end
    else # case == "infra"
        # copy over css files
        # NOTE some processing may be further added here later on.
        if splitext(fpair.second)[2] == ".css"
            cp(joinpath(fpair...), joinpath(JD_PATHS[:out_css], fpair.second),
                force=true)
        end
    end

    return
end


"""
    change_ext(fname)

Convenience function to replace the extension of a filename with another.
"""
change_ext(fname, ext=".html") = splitext(fname)[1] * ext
