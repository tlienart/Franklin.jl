"""
    prepare_output_dir(clear_out_dir)

Prepare the output directory `JD_PATHS[:out]`.

* `clear_out_dir` removes the content of the output directory if it exists to
start from a blank slate
"""
function prepare_output_dir(clear_out=true)
    # if required to start from a blank slate -> remove the output dir
    (clear_out & isdir(JD_PATHS[:out])) && rm(JD_PATHS[:out], recursive=true)
    # create the output dir and the css dir if necessary
    !isdir(JD_PATHS[:out]) && mkdir(JD_PATHS[:out])
    !isdir(JD_PATHS[:out_css]) && mkdir(JD_PATHS[:out_css])
end


"""
    out_path(root)

Take a `root` path to an input file and convert to output path. If the output
path does not exist, create it.
"""
function out_path(root::String)
    f_out_path = JD_PATHS[:f] * root[length(JD_PATHS[:in])+1:end]
    f_out_path = replace(f_out_path, "/pages/" => "/pub/")
    !ispath(f_out_path) && mkpath(f_out_path)
    return f_out_path
end


"""
    scan_input_dir!(md_files, html_files, other_files, infra_files, verb)

Update the dictionaries referring to input files and their time of last
change. The variable `verb` propagates verbosity.
"""
function scan_input_dir!(md_files, html_files, other_files,
                         infra_files, verb=false)
    # top level files (src/*)
    for file ∈ readdir(JD_PATHS[:in])
        fname, fext = splitext(file)
        fpair = normpath(JD_PATHS[:in] * "/")=>file
        if file == "config.md"
            add_if_new_file!(infra_files, fpair, verb)
        elseif fext == ".md"
            add_if_new_file!(md_files, fpair, verb)
        else
            add_if_new_file!(html_files, fpair, verb)
        end
    end
    # pages files (src/pages/*)
    for (root, _, files) ∈ walkdir(JD_PATHS[:in_pages])
        # ensure there's a "/" at the end of the root
        nroot = normpath(root * "/")
        for file ∈ files
            # skip if it has to be ignored
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
    # infastructure files (src/_css/* and src/_html_parts/*)
    for d ∈ [:in_css, :in_html], (root, _, files) ∈ walkdir(JD_PATHS[d])
        nroot = normpath(root * "/")
        for file ∈ files
            fname, fext = splitext(file)
            # skipping files that are not of the type INFRA_EXT
            fext ∉ INFRA_EXT && continue
            add_if_new_file!(infra_files, nroot=>file, verb)
        end
    end
end


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
