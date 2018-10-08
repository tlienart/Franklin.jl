"""
    last(f)

Convenience function to get the time of last modification of a file.
"""
last(f::String) = stat(f).mtime


"""
    process_config()

Checks for a `config.md` file in `JD_PATHS[:in]` and uses it to set the global
variables referenced in `JD_GLOB_VARS` it also sets the global latex commands
via `JD_GLOB_LXDEFS`. If the configuration file is not found a warning is
shown.
"""
function process_config()
    # read the config.md file if it is present
    config_path = joinpath(JD_PATHS[:in], "config.md")
    if isfile(config_path)
        convert_md(read(config_path, String) * EOS; isconfig=true)
    else
        @warn "I didn't find a config file. Ignoring."
    end
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
    content = convert_html(string(content), jd_vars)
    head, pg_foot, foot = (e->convert_html(e, jd_vars)).([head, pg_foot, foot])
    ###
    # 4. construct the page proper
    ###
    pg = head * "<div class=content>\n" * content * pg_foot * "</div>\n" * foot
    ###
    # 5. write the html file where appropriate
    ###
    write(joinpath(out_path(root), change_ext(file)), pg)
end


function process_file(case, fpair, clear_out_dir,
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
        if clear_out_dir || !isfile(opath) || last(opath) < t
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
end


"""
    change_ext(fname)

Convenience function to replace the extension of a filename with another.
"""
change_ext(fname, ext=".html") = splitext(fname)[1] * ext
