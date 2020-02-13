#=
Functionalities to manage files in the context of code evaluation.

- script files (can be read and written)
- output files (written, = where stdout is redirected)
=#

"""
$(SIGNATURES)

Internal function to take a relative path and return a unix version of the path
(if it isn't already). Used in [`resolve_rpath`](@ref).
"""
function unixify(rpath::AS)::AS
    # if empty, return "/"
    isempty(rpath) && return "/"
    # if windows, replace "\\" by "/"
    Sys.isunix() || (rpath = replace(rpath, "\\" => "/"))
    # if it has an extension e.g.: /blah.txt, return
    isempty(splitext(rpath)[2]) || return rpath
    # if it doesn't have an extension, check if it ends with `/` e.g. : /blah/
    # if it doesn't end with "/", add one and return
    endswith(rpath, "/") || return rpath * "/"
    return rpath
end

"""
$(SIGNATURES)

Internal function to take a unix path, split it along `/` and re-join it
(which will lead to the same path on unix but not on Windows).
This undoes what [`unixify`](@ref) does.
"""
join_rpath(rpath::AS) = joinpath(split(rpath, '/')...)

"""
$(SIGNATURES)

Internal function to parse a relative path and return either a path relative
to the website root folder or the website assets folder or a full system path.
This doesn't check whether the  path points to  an existing asset (for that
see [`resolve_rpath`](@ref).

* `/[path]`:  this is a path relative to the website root folder, e.g.:
              `/foo/figs/img1.png`.
* `[path]`:   this is a path relative to the site assets folder, e.g.:
              `/assets/foo`.
* `./[path]`: this is a path relative to the assets folder with the same path
              as the calling page. For instance, `./im1.png` in
              `src/pages/pg1.md` will point to `/assets/pages/pg1/im1.png`.

Otherwise, if in `code` mode, recurse with `./code/path`.

## Argument

1. `rpath`: the relative path (always in Unix format)

## Keywords

* `canonical=false`: whether to return a full path on the system (`true`) or
                     a unix-path relative to the website root folder (`false`).
* `code=false`:      whether we're in a code context or not (in which case an
                     additional shortcut form is allowed).
"""
function parse_rpath(rpath::AS; canonical::Bool=false, code::Bool=false)::AS

    FS2 = FD_ENV[:STRUCTURE] >= v"0.2"

    # path from the website root folder
    # examples with FS2:
    # /foo.bar          ==> { /foo.bar        ; [__site]/foo.bar        }
    # /_assets/foo.bar  ==> { /assets/foo.bar ; [__site]/assets/foo.bar }
    #
    if startswith(rpath, "/")
        if length(rpath) <= 1
            throw(RelativePathError("Relative path `$rpath` doesn't " *
                                    "look right."))
        end
        if FS2
            rpath = replace(rpath, "/_assets" => "/assets")
        end
        canonical || return rpath
        if FS2
            full_path = joinpath(PATHS[:site], join_rpath(rpath[2:end]))
        else
            full_path = joinpath(PATHS[:folder], join_rpath(rpath[2:end]))
        end
        return normpath(full_path)

    # path relative to the assets folder with the same path as the parent file
    # example with FS2 assuming we're on page /page/
    # ./foo.bar ==> { /assets/page/foo.bar  ; [__site]/assets/page/foo.bar}
    elseif startswith(rpath, "./")
        if length(rpath) <= 2
            throw(RelativePathError("Relative path `$rpath` doesn't " *
                                    "look right."))
        end
        if !canonical
            # here we want to remain unix-style, so we don't use joinpath
            # note that rpath never starts with "/" so there's
            # no doubling of "//"
            rpath = unixify(splitext(locvar("fd_rpath"))[1]) * rpath[3:end]
            return "/assets/" * rpath
        else
            if FS2
                full_path = joinpath(PATHS[:site], "assets",
                                     splitext(locvar("fd_rpath"))[1],
                                     join_rpath(rpath[3:end]))
            else
                full_path = joinpath(PATHS[:assets],
                                     splitext(locvar("fd_rpath"))[1],
                                     join_rpath(rpath[3:end]))
            end
            return normpath(full_path)
        end
    end

    # if the rpath didn't start with "/" or "./", check if it's not empty
    # and if we're in a code context
    if iszero(length(rpath))
        throw(RelativePathError("Relative path `$rpath` (empty) isn't right."))
    end
    if code # recurse adding "./"
        return parse_rpath("./code/" * rpath; canonical=canonical)
    end
    # otherwise, we consider the path as a full path relative to the
    # /assets/ folder. For instance `blah/img1.png` => `/assets/blah/img1.png`
    canonical || return "/assets/" * rpath # no doubling bc rpath[1] != '/'
    if FS2
        full_path = joinpath(PATHS[:site], "assets", join_rpath(rpath))
    else
        full_path = joinpath(PATHS[:assets], join_rpath(rpath))
    end
    return normpath(full_path)
end

"""
$(SIGNATURES)

Internal function to resolve an input (usually a script in a given language)
given a relative path (in unix format) and return a tuple with:

* the full system path to the asset
* the full system path to the directory containing the asset
* the name of the asset without its extension

If an extension is not provided, Franklin will try to find something with an
adequate extension or, failing that, will try to find anything that matches
the file name.
"""
function resolve_rpath(rpath::AS, lang::AS="")::NTuple{3,String}
    # parse the relative path
    fpath = parse_rpath(rpath; canonical=true, code=!isempty(lang))

    # check if an extension is given, if not, consider it's
    # `.xx` with language `nothing`
    fp, ext = splitext(fpath)
    if isempty(ext)
        ext, = get(CODE_LANG, lang) do
            (".xx", nothing)
        end
        fpath *= ext
    end
    dir, fname = splitdir(fp)

    # If there's an extension, check the file exists and return
    if ext != ".xx"
        isfile(fpath) && return fpath, dir, fname
        throw(FileNotFoundError("Couldn't find a file when trying to " *
                "resolve an input request with relative path: `$rpath`."))
    end

    # Otherwise there's no extension, try to find a file with
    # a matching name
    if !isdir(dir)
        throw(FileNotFoundError("Couldn't find a file when trying to " *
                "resolve an input request with relative path: `$rpath`."))
    end
    files = readdir(dir)
    k     = findfirst(e -> splitext(e)[1] == fname, files)

    # if nothing is found, error
    if isnothing(k)
        throw(FileNotFoundError("Couldn't find a file when trying to " *
                "resolve an input request with relative path: `$rpath`."))
    end

    # otherwise resolve and return
    fname_ext = files[k]
    fpath     = joinpath(dir, fname_ext)
    fname     = splitext(fname_ext)[1]

    return fpath, dir, fname
end

"""
$SIGNATURES

A convenience internal function to get the system paths related to a code
script these paths are given raw, without checking whether things exist.
"""
function form_codepaths(rpath::AS)::NamedTuple
    path        = parse_rpath(rpath; canonical=true, code=true)
    # extension-less names are allowed
    script_path = ifelse(endswith(path, ".jl"), path, path * ".jl")
    dir, fname  = splitdir(script_path)
    fname_noext = splitext(fname)[1]
    out_dir     = joinpath(dir, "output")
    out_path    = joinpath(out_dir, fname_noext * ".out")
    res_path    = joinpath(out_dir, fname_noext * ".res")
    # return everything
    return (script_path = script_path,
            script_dir  = dir,
            script_name = fname,
            out_dir     = out_dir,
            out_path    = out_path,
            res_path    = res_path)
end
