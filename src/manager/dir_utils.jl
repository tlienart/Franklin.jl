"""
TrackedFiles

Convenience type to keep track of files to watch.
"""
const TrackedFiles = Dict{Pair{String, String}, Float64}


"""
$(SIGNATURES)

Prepare the output directory `PATHS[:pub]`.

* `clear=true` removes the content of the output directory if it exists to start from a blank
slate
"""
function prepare_output_dir(clear::Bool=true)::Nothing
    # if required to start from a blank slate -> remove the output dir
    (clear & isdir(PATHS[:pub])) && rm(PATHS[:pub], recursive=true)
    # create the output dir and the css dir if necessary
    !isdir(PATHS[:pub]) && mkdir(PATHS[:pub])
    !isdir(PATHS[:css]) && mkdir(PATHS[:css])
    return nothing
end


"""
$(SIGNATURES)

Take a `root` path to an input file and convert to output path. If the output path does not exist,
create it.
"""
function out_path(root::String)::String
    len_in = lastindex(joinpath(PATHS[:src], ""))
    length(root) <= len_in && return PATHS[:folder]
    dpath = root[nextind(root, len_in):end]
    # construct the out path
    f_out_path = joinpath(PATHS[:folder], dpath)
    f_out_path = replace(f_out_path, r"([^a-zA-Z\d\s_:])pages" => s"\1pub")
    # if it doesn't exist, make the path
    !ispath(f_out_path) && mkpath(f_out_path)
    return f_out_path
end


"""
$(SIGNATURES)

Update the dictionaries referring to input files and their time of last change. The variable `verb`
propagates verbosity.
"""
function scan_input_dir!(md_files::TrackedFiles, html_files::TrackedFiles,
                         other_files::TrackedFiles, infra_files::TrackedFiles,
                         literate_files::TrackedFiles, verb::Bool=false)::Nothing
    # top level files (src/*)
    for file ∈ readdir(PATHS[:src])
        isfile(joinpath(PATHS[:src], file)) || continue
        # skip if it has to be ignored
        file ∈ IGNORE_FILES && continue
        fname, fext = splitext(file)
        fpair = (PATHS[:src] => file)
        if file == "config.md"
            add_if_new_file!(infra_files, fpair, verb)
        elseif fext == ".md"
            add_if_new_file!(md_files, fpair, verb)
        else
            add_if_new_file!(html_files, fpair, verb)
        end
    end
    # pages files (src/pages/*)
    for (root, _, files) ∈ walkdir(PATHS[:src_pages])
        for file ∈ files
            isfile(joinpath(root, file)) || continue
            # skip if it has to be ignored
            file ∈ IGNORE_FILES && continue
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
    for d ∈ (:src_css, :src_html), (root, _, files) ∈ walkdir(PATHS[d])
        for file ∈ files
            isfile(joinpath(root, file)) || continue
            fname, fext = splitext(file)
            # skipping files that are not of the type INFRA_FILES
            fext ∉ INFRA_FILES && continue
            add_if_new_file!(infra_files, root=>file, verb)
        end
    end
    # literate script files if any, note that the folder may not exist
    if isdir(PATHS[:literate])
        for (root, _, files) ∈ walkdir(PATHS[:literate])
            for file ∈ files
                isfile(joinpath(root, file)) || continue
                fname, fext = splitext(file)
                # skipping files that are not script file
                fext != ".jl" && continue
                add_if_new_file!(literate_files, root=>file, verb)
            end
        end
    end
    return nothing
end


"""
$(SIGNATURES)

Helper function, if `fpair` is not referenced in the dictionary (new file) add the entry to the
dictionary with the time of last modification as val.
"""
function add_if_new_file!(dict::TrackedFiles, fpair::Pair{String,String}, verb::Bool)::Nothing
    haskey(dict, fpair) && return nothing
    # it's a new file
    verb && println("tracking new file '$(fpair.second)'.")
    dict[fpair] = mtime(joinpath(fpair...))
    return nothing
end
