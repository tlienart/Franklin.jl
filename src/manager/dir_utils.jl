"""
TrackedFiles

Convenience type to keep track of files to watch.
"""
const TrackedFiles = Dict{Pair{String, String}, Float64}


"""
$SIGNATURES

Prepare the output directory `PATHS[:pub]`. If the environment variable CLEAR
is true then the output folder is erased first (can be helpful to clean things
and truly start from scratch).
"""
function prepare_output_dir()::Nothing
    clear = FD_ENV[:CLEAR]
    (clear & isdir(path(:site))) && rm(path(:site), recursive=true)
    !isdir(path(:site)) && mkdir(path(:site))
    return nothing
end

"""
$(SIGNATURES)

Given a file path split in `(base, file)`, form the output path (where the
output file will be written/copied).
"""
function form_output_path(base::AS, file::AS, case::Symbol)
    # .md -> .html for md pages:
    case == :md && (file = change_ext(file))
    outbase = _out_path(base)
    if case in (:md, :html)
        # file is index.html or 404.html or in keep_path --> keep the path
        # file is page.html  --> .../page/index.html
        fname = splitext(file)[1]
        if fname != "index" && !endswith(fname, "/index") && !_keep_path(base, fname)
            file = joinpath(fname, "index.html")
        end
    end
    outpath = joinpath(outbase, file)
    outdir  = splitdir(outpath)[1]
    isdir(outdir) || mkpath(outdir)
    return outpath
end

function _out_path(base::String)::String
    if startswith(base, path(:assets)) ||
       startswith(base, path(:css))    ||
       startswith(base, path(:layout)) ||
       startswith(base, path(:libs))   ||
       startswith(base, path(:literate))

       # add a closing separator to folder path
       rbase   = joinpath(path(:folder), "") * "_"
       outpath = base[nextind(base, lastindex(rbase)):end]
       outpath = joinpath(path(:site), outpath)
   else
       # path is not a 'special folder'
       outpath = replace(base, path(:folder) => path(:site))
   end
    return outpath
end

function _keep_path(base, fname)::Bool
    rpath = get_rpath(joinpath(base, fname))
    keep  = union(globvar(:keep_path)::Vector{String}, ["404.html", "404"])
    isempty(keep) && return false
    files = [f for f in keep if endswith(f, ".html")]
    dirs = [d for d in keep if endswith(d, "/")]
    spath = rpath * ".html"
    any(f -> f == spath, files) && return true
    any(d -> startswith(spath, d), dirs) && return true
    return false
end

"""
$(SIGNATURES)

A user can provide a slug which will then specify the output path.
There is the underlying assumption that the path will not clash.
"""
function form_custom_output_path(slug::String)
    # a slug is assumed to be `aa` or `aa/bb`
    # extensions will be ignored, pre and post backslash as well
    # --> aa/bb.html -> aa/bb (effectively aa/bb/index.html)
    # --> /aa/bb/cc/ --> aa/bb/cc (effectively aa/bb/cc/index.html)
    slug = strip(splitext(slug)[1], '/')
    set_var!(LOCAL_VARS, "fd_url", "/" * joinpath(slug, "index.html"))
    # form the path
    p = mkpath(joinpath(path(:site), slug))
    return joinpath(p, "index.html")
end


_access(p) = p
_access(p::Regex) = p.pattern
_isempty(p)  = isempty(_access(p))
_endswith(p) = endswith(_access(p), '/')


"""
$(SIGNATURES)

Update the dictionaries referring to input files and their time of last change.
The variable `verb` propagates verbosity.
"""
function scan_input_dir!(args...; kw...)
    to_ignore = union(IGNORE_FILES, globvar("ignore"))
    # remove empty patterns or strings
    filter!(!_isempty, to_ignore)
    # differentiate between files and dirs pattern
    dir_indicator = [_endswith(c) for c in to_ignore]
    # ignore "/"
    d2i = filter!(d -> length(d) > 1, to_ignore[dir_indicator])
    f2i = to_ignore[.!dir_indicator]
    return _scan_input_dir!(args...; files2ignore=f2i, dirs2ignore=d2i, kw...)
end

function _scan_input_dir!(other_files::TrackedFiles,
                           infra_files::TrackedFiles,
                           md_pages::TrackedFiles,
                           html_pages::TrackedFiles,
                           literate_scripts::TrackedFiles,
                           verb::Bool=false;
                           in_loop::Bool=false,
                           files2ignore::Vector=String[],
                           dirs2ignore::Vector=String[])::Nothing
    # go over all files in the website folder
    for (root, _, files) ∈ walkdir(path(:folder))
        for file in files
            # assemble full path (root is an absolute path)
            fpath = joinpath(root, file)
            fpair = root => file
            fext  = splitext(file)[2]

            opts = (fpair, verb, in_loop)

            # early skips
            !isfile(fpath) && continue
            should_ignore(fpath, files2ignore, dirs2ignore) && continue

            # skip over `__site` folder, `.git` and `.github` folder
            startswith(fpath, path(:site)) && continue
            startswith(fpath, joinpath(path(:folder), ".git")) && continue

            # TOML files are not tracked but are copied over
            if fext == ".toml"
                add_if_new_file!(other_files, opts...)
            # assets file --> other
            elseif startswith(fpath, path(:assets))
                add_if_new_file!(other_files, opts...)
            # infra_files
            elseif startswith(fpath, path(:css))    ||
                   startswith(fpath, path(:layout)) ||
                   startswith(fpath, path(:libs))
                add_if_new_file!(infra_files, opts...)
            # literate_files
            elseif startswith(fpath, path(:literate))
                # ignore files that are not script files
                fext == ".jl" || continue
                add_if_new_file!(literate_scripts, opts...)
            else
                if file == "config.md"
                    add_if_new_file!(infra_files, opts...)
                elseif file == "utils.jl"
                    add_if_new_file!(infra_files, opts...)
                elseif fext == ".md"
                    add_if_new_file!(md_pages, opts...)
                elseif fext ∈ (".html", ".htm")
                    add_if_new_file!(html_pages, opts...)
                else
                    add_if_new_file!(other_files, opts...)
                end
            end
        end
    end
    return nothing
end


"""
$SIGNATURES

Helper function, if `fpair` is not referenced in the dictionary (new file) add
the entry to the dictionary with the time of last modification as val.
"""
function add_if_new_file!(dict::TrackedFiles, fpair::Pair{String,String},
                          verb::Bool, in_loop::Bool=false)::Nothing
    haskey(dict, fpair) && return nothing
    # it's a new file
    verb && println("tracking new file '$(fpair.second)'.")
    # save it's modification time, set to zero if it's a new file in a loop
    # to force its processing in FS2
    dict[fpair] = ifelse(in_loop, 0, mtime(joinpath(fpair...)))
    return nothing
end


"""
$SIGNATURES

Check if a file path should be ignored. This is a helper function for the
`scan_input_dir` functions. A bit of a similar principle to `match_url`. The
file argument is an absolute path, the list would be a list of relative paths.
Rules:

* `''` or `'/'`  -> ignore
* `'path/fname'` -> ignore exactly that
* `'path/dir/'`  -> ignore everything starting with `path/dir/`
"""
function should_ignore(fpath::AS, files2ignore::Vector,
                       dirs2ignore::Vector)::Bool
    # fpath is necessarily an absolute path so can strip the folder part
    fpath = fpath[length(path(:folder))+length(PATH_SEP)+1:end] |> unixify
    if any(c -> c isa Regex ? match(c, fpath) !== nothing : c == fpath,
               files2ignore)
        return true
    end
    flag = findfirst(c -> startswith(fpath, c), dirs2ignore)
    isnothing(flag) || return true
    return false
end
