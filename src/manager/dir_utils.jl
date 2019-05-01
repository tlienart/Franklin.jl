"""
JD_FILES_DICT

Convenience type to keep track of files to watch.
"""
const JD_FILES_DICT = Dict{Pair{String, String}, Float64}

"""
$(SIGNATURES)

Prepare the output directory `JD_PATHS[:out]`.

* `clear=true` removes the content of the output directory if it exists to start from a blank
slate
"""
function prepare_output_dir(clear::Bool=true)::Nothing
    # if required to start from a blank slate -> remove the output dir
    (clear & isdir(JD_PATHS[:out])) && rm(JD_PATHS[:out], recursive=true)

    # create the output dir and the css dir if necessary
    !isdir(JD_PATHS[:out]) && mkdir(JD_PATHS[:out])
    !isdir(JD_PATHS[:out_css]) && mkdir(JD_PATHS[:out_css])

    return nothing
end


"""
$(SIGNATURES)

Take a `root` path to an input file and convert to output path. If the output path does not exist,
create it.
"""
function out_path(root::String)::String
    len_in = lastindex(joinpath(JD_PATHS[:in], ""))
    length(root) <= len_in && return JD_PATHS[:f]

    dpath = root[nextind(root, len_in):end]

    f_out_path = joinpath(JD_PATHS[:f], dpath)
    f_out_path = replace(f_out_path, r"([^a-zA-Z\d\s_:])pages" => s"\1pub")
    !ispath(f_out_path) && mkpath(f_out_path)

    return f_out_path
end


"""
$(SIGNATURES)

Update the dictionaries referring to input files and their time of last change. The variable `verb`
propagates verbosity.
"""
function scan_input_dir!(md_files::JD_FILES_DICT, html_files::JD_FILES_DICT,
                         other_files::JD_FILES_DICT, infra_files::JD_FILES_DICT,
                         verb::Bool=false)::Nothing
    # top level files (src/*)
    for file ∈ readdir(JD_PATHS[:in])
        isfile(joinpath(JD_PATHS[:in], file)) || continue
        # skip if it has to be ignored
        file ∈ JD_IGNORE_FILES && continue
        fname, fext = splitext(file)
        fpair = (JD_PATHS[:in] => file)
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
        for file ∈ files
            isfile(joinpath(root, file)) || continue
            # skip if it has to be ignored
            file ∈ JD_IGNORE_FILES && continue
            fname, fext = splitext(file)
            fpair = (root => file)
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
        for file ∈ files
            isfile(joinpath(root, file)) || continue
            fname, fext = splitext(file)
            # skipping files that are not of the type JD_INFRA_EXT
            fext ∉ JD_INFRA_EXT && continue
            add_if_new_file!(infra_files, root=>file, verb)
        end
    end
    return nothing
end


"""
$(SIGNATURES)

Helper function, if `fpair` is not referenced in the dictionary (new file) add the entry to the
dictionary with the time of last modification as val.
"""
function add_if_new_file!(dict::JD_FILES_DICT, fpair::Pair{String,String}, verb::Bool)::Nothing
    haskey(dict, fpair) && return nothing
    # it's a new file
    verb && println("tracking new file '$(fpair.second)'.")
    dict[fpair] = mtime(joinpath(fpair...))
    return nothing
end
