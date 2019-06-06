"""
$(SIGNATURES)

Checks for a `config.md` file in `JD_PATHS[:in]` and uses it to set the global variables referenced
in `JD_GLOB_VARS` it also sets the global latex commands via `JD_GLOB_LXDEFS`. If the configuration
file is not found a warning is shown.
"""
function process_config()::Nothing
    # read the config.md file if it is present
    config_path = joinpath(JD_PATHS[:in], "config.md")
    if isfile(config_path)
        convert_md(read(config_path, String) * EOS; isconfig=true)
    else
        @warn "I didn't find a config file. Ignoring."
    end

    if JD_GLOB_VARS["codetheme"].first !== nothing
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
$(SIGNATURES)

Take a path to an input markdown file (via `root` and `file`), then construct the appropriate HTML
page (inserting `head`, `pg_foot` and `foot`) and finally write it at the appropriate place.
"""
function write_page(root::String, file::String, head::String, pg_foot::String, foot::String;
                    prerender::Bool=false, isoptim::Bool=false)::Nothing
    # 0. create a dictionary with all the variables available to the page
    # 1. read the markdown into string, convert it and extract definitions
    # 2. eval the definitions and update the variable dictionary, also retrieve
    # document variables (time of creation, time of last modif) and add those
    # to the dictionary.
    jd_vars = merge(JD_GLOB_VARS, copy(JD_LOC_VARS))
    fpath   = joinpath(root, file)
     # The curpath is the relative path starting after /src/ so for instance:
     # f1/blah/page1.md or index.md etc... this is useful in the code evaluation and management
     # of paths
    JD_CURPATH[] = fpath[lastindex(JD_PATHS[:in])+2:end]

    vJD_GLOB_LXDEFS    = collect(values(JD_GLOB_LXDEFS))
    (content, jd_vars) = convert_md(read(fpath, String) * EOS, vJD_GLOB_LXDEFS)

    # adding document variables to the dictionary
    # note that some won't change and so it's not necessary to do this every time
    # but it takes negligible time to do this so ¯\_(ツ)_/¯ (and it's less annoying than
    # to keep tabs on which file has already been treated etc).
    s = stat(fpath)
    set_var!(jd_vars, "jd_ctime", jd_date(unix2datetime(s.ctime)))
    set_var!(jd_vars, "jd_mtime", jd_date(unix2datetime(s.mtime)))
    set_var!(jd_vars, "jd_rpath", JD_CURPATH[])

    # 3. process blocks in the html infra elements based on `jd_vars`
    # (e.g.: add the date in the footer)
    content = convert_html(str(content), jd_vars, fpath)
    head, pg_foot, foot = (e->convert_html(e, jd_vars, fpath)).([head, pg_foot, foot])

    # 4. construct the page proper & prerender if needed
    pg = build_page(head, content, pg_foot, foot)

    if prerender
        # KATEX
        pg = js_prerender_katex(pg)
        # HIGHLIGHT
        if JD_CAN_HIGHLIGHT
            pg = js_prerender_highlight(pg)
            # remove script TODO: needs to be documented
            pg = replace(pg, r"<script.*?(?:highlight\.pack\.js|initHighlightingOnLoad).*?<\/script>"=>"")
        end
        # remove katex scripts TODO: needs to be documented
        pg = replace(pg, r"<script.*?(?:katex\.min\.js|auto-render\.min\.js|renderMathInElement).*?<\/script>"=>"")
    end

    if !isempty(JD_GLOB_VARS["prepath"].first) && isoptim
        pg = fix_links(pg)
    end

    # 5. write the html file where appropriate
    write(joinpath(out_path(root), change_ext(file)), pg)

    return nothing
end


"""
$(SIGNATURES)

See [`process_file_err`](@ref).
"""
function process_file(case::Symbol, fpair::Pair{String,String}, args...; kwargs...)::Int
    try
        process_file_err(case, fpair, args...; kwargs...)
    catch err
        JD_DEBUG[] && throw(err)
        rp = fpair.first
        rp = rp[end-min(20, length(rp))+1 : end]
        println("\n... error processing '$(fpair.second)' in ...$rp.")
        println("Verify, then start judoc again...\n")
        @show err
        return -1
    end
    return 0
end


"""
$(SIGNATURES)

Considers a source file which, depending on `case` could be a html file or a file in judoc markdown
etc, located in a place described by `fpair`, processes it by converting it and adding appropriate
header and footer and writes it to the appropriate place. It can throw an error which will be
caught in `process_file(args...)`.
"""
function process_file_err(case::Symbol, fpair::Pair{String, String}, head::AbstractString="",
                          pg_foot::AbstractString="", foot::AbstractString="", t::Float64=0.;
                          clear::Bool=false, prerender::Bool=false, isoptim::Bool=false)::Nothing
    if case == :md
        write_page(fpair..., head, pg_foot, foot; prerender=prerender, isoptim=isoptim)
    elseif case == :html
        fpath = joinpath(fpair...)
        raw_html = read(fpath, String)
        proc_html = convert_html(raw_html, JD_GLOB_VARS, fpath; isoptim=isoptim)
        write(joinpath(out_path(fpair.first), fpair.second), proc_html)
    elseif case == :other
        opath = joinpath(out_path(fpair.first), fpair.second)
        # only copy it again if necessary (particularly relevant when the asset files
        # take quite a bit of space.
        if clear || !isfile(opath) || mtime(opath) < t
            cp(joinpath(fpair...), opath, force=true)
        end
    else # case == :infra
        # copy over css files
        # NOTE some processing may be further added here later on.
        if splitext(fpair.second)[2] == ".css"
            cp(joinpath(fpair...), joinpath(JD_PATHS[:out_css], fpair.second),
                force=true)
        end
    end
    return nothing
end


"""
$(SIGNATURES)

Convenience function to replace the extension of a filename with another.
"""
change_ext(fname::AbstractString, ext=".html")::String = splitext(fname)[1] * ext


"""
$(SIGNATURES)

Convenience function to assemble the html out of its parts.
"""
build_page(head::String, content::String, pg_foot::String, foot::String)::String =
    "$head\n<div class=\"jd-content\">\n$content\n$pg_foot\n</div>\n$foot"


"""
$(SIGNATURES)

for a project website, for instance `username.github.io/project/` all paths should eventually
be pre-prended with `/project/`. This would happen just before you publish the website.
"""
function fix_links(pg::String)::String
    pp = strip(JD_GLOB_VARS["prepath"].first, '/')
    ss = SubstitutionString("\\1=\"/$(pp)/")
    return replace(pg, r"(src|href)\s*?=\s*?\"\/" => ss)
end
