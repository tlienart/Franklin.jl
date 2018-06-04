@static if VERSION < v"0.7.0-DEV.2005"
    using Base.Markdown: html
else
    using Markdown: html
end

"""
    set_vars!(def_dict, new_Defs)

Given a set of definitions `defs`, update a dictionary `def_dict`. If the keys
do not match, entries are ignored and a warning message is displayed.

E.g.:

    d = Dict("a"=>[0.5, (Real,)], "b"=>["hello", (String,)])
    set_vars!(d, [("a", "=5.0"), ("b", "= \"goodbye\"")])

Will return

    Dict{String,Any} with 2 entries:
      "b" => "goodbye"
      "a" => 5.0
"""
function set_vars!(def_dict=Dict, new_defs=Tuple{String, String}[])
    if !isempty(new_defs)
        # try to assign
        for (key, new_def) ∈ new_defs
            if haskey(def_dict, key)
                tmp = parse("__tmp__" * new_def)
                try
                    # try to evaluate the assignment
                    tmp = eval(tmp)
                catch err
                    warn("I got an error trying to evaluate '$tmp', fix the assignment.")
                    throw(err)
                end
                # if the retrieved value has the right type
                # assign it to the corresponding value
                ttmp = typeof(tmp)
                if any(issubtype(ttmp, tᵢ) for tᵢ ∈ def_dict[key][2])
                    def_dict[key][1] = tmp
                else
                    warn("Doc var '$key' (types: $(def_dict[key][2])) can't be set to value '$tmp' (type: $ttmp). Assignment ignored.")
                end
            else
                warn("Doc var name '$key' is unknown. Assignment ignored.")
            end
        end
    end
end


"""
    convert_md!(dict_vars, md_string)

Take a raw MD string, process (and put away) the blocks, then parse the rest
using the default html parser. Finally, plug back in the processed content that
was put away and return the corresponding HTML string.
The dictionary `dict_vars` containing the document and the page variables is
updated once the local definitions have been read.
"""
function convert_md!(dict_vars, md_string)
    # -- Comments
    md_string = remove_comments(md_string)

    # -- Variables
    (md_string, defs) = extract_page_defs(md_string)
    set_vars!(dict_vars, defs)

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
    convert_dir(clear_out_dir, rewrite_css)

Take a directory that contains markdown files (possibly in subfolders), convert
all markdown files to html and reproduce the same structure to an output dir.

* `clear_out_dir` destroys what was previously in `out_dir` (outside of PATH_CSS
and PATH_LIBS) before bringing new files, this can be useful if file names have
been changed etc to get rid of stale files.
"""
function convert_dir(clear_out_dir=true)

    ###
    # 0. PREPROCESSING OF DIRECTORIES
    # -- note that the all-caps variables are defined outside (cf. JuDoc.jl)
    # -- adjusting given strings
    # -- adding LIBS and CSS
    # -- cleaning up past files if necessary
    ###

    # read path variables from Main environment (see JuDoc.jl)
    set_paths!()

    # if required to start from a blank slate, we remove everything in
    # the output dir
    if clear_out_dir && isdir(PATHS[:out])
        rm(PATHS[:out], recursive=true)
    end

    if !isdir(PATHS[:out])
        mkdir(PATHS[:out])
    end

    # the two `if` blocks are executed only when starting from a blank slate
    # so, in theory, one may one to do some direct adjustments in the output
    # dir and those wouldn't get overwritten provided clear_out_dir=false
    # this is NOT RECOMMENDED but possible.
    if !isdir(PATHS[:out_css])
        # copying template CSS files
        cp(PATHS[:in_css], PATHS[:out_css])
    end
    if !isdir(PATHS[:out_libs])
        # copying libs
        cp(PATHS[:in_libs], PATHS[:out_libs])
    end

    ###
    # 1. DEFAULT VAR DICTIONARIES
    # -- create default dictionaries of variables for the website and the pages
    # -- NOTE: the dictionaries are merged on pages, so the keys cannot clash
    # -- the values are of the form [default, (type1, type2)] where the tuple
    #    contains the types for this key that will be accepted.
    ###
    # doc_vars is a fixed dictionary (for the entire website)
    doc_vars = Dict(
        "author" => ["THE AUTHOR", (String, Void)])

    # default page vars (copied and, potentially, modified by each page)
    page_vars_default = Dict(
        "hasmath" => [true, (Bool,)],
        "hascode" => [true, (Bool,)],
        "isnotes" => [true, (Bool,)],
        "title"   => ["THE TITLE", (String,)],
        "date"    => [Date(), (String, Date, Void)])

    # read the config.md file if it is present
    config_path = joinpath(PATHS[:in], "config.md")
    if isfile(config_path)
        convert_md!(doc_vars, readstring(config_path))
    else
        warn("I didn't find a config file. Ignoring.")
    end

    ###
    # 2. CONVERSION & WRITING FILES
    # -- finding the files
    # -- converting them if required
    # -- writing / copying them at right place
    ###

    head_html = readstring(PATHS[:in_html] * "head.html")
    foot_html = readstring(PATHS[:in_html] * "foot.html")
    foot_content_html = readstring(PATHS[:in_html] * "foot_content.html")

    length_in_dir = length(PATHS[:in])

    for (root, _, files) ∈ walkdir(PATHS[:in])
        for file ∈ files
            fname, fext = splitext(file)
            if fext == ".md" && fname != "config"
                ###
                # 1. read markdown into string
                # 2. convert to html
                # 3. add head / foot from template
                # 4. write at appropriate place
                ###
                all_vars = merge(doc_vars, deepcopy(page_vars_default))
                md_string = readstring(joinpath(root, file))
                html_string = convert_md!(all_vars, md_string)

                web_html = process_braces_blocks(head_html, all_vars)
                web_html *= "<div class=content>\n"
                web_html *= html_string
                web_html *= process_braces_blocks(foot_content_html, all_vars)
                web_html *= "\n</div>" # content
                web_html *= process_braces_blocks(foot_html, all_vars)

                f_out_name = fname * ".html"
                f_out_path = PATHS[:out] * root[length_in_dir+1:end] * "/"
                if !ispath(f_out_path)
                    mkpath(f_out_path)
                end

                write(f_out_path * f_out_name, web_html)

            else
                # copy at appropriate place
                f_out_path = PATHS[:out] * root[length_in_dir+1:end]
                if !ispath(f_out_path)
                    mkpath(f_out_path)
                end
                cp(joinpath(root, file), joinpath(f_out_path, file),
                    remove_destination=true)
            end
        end
    end # walkdir
end
