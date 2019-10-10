# See src/jd_vars : def_GLOBAL_LXDEFS

"""
$SIGNATURES

Internal function to resolve a `\\output{rpath}` (finds the output of a code block and shows it).
The `reprocess` argument indicates whether the output should be processed as judoc markdown or
inserted as is.
"""
function resolve_lx_output(lxc::LxCom; reprocess::Bool=false)::String
    rpath = strip(content(lxc.braces[1])) # [assets]/subpath/script{.jl}
    return resolve_lx_input_plainoutput(rpath, reprocess; code=true)
end


"""
$SIGNATURES

Internal function to resolve a `\\show{rpath}` (finds the result of a code block and shows it).
No reprocess for this.
"""
function resolve_lx_show(lxc::LxCom; reprocess::Bool=false)::String
    rpath = strip(content(lxc.braces[1]))
    show_res(rpath)
end



"""
$SIGNATURES

Internal function to resolve a `\\textoutput{rpath}` (finds the output of a code block and shows
after treating it as markdown to be parsed).
"""
resolve_lx_textoutput(lxc::LxCom) = resolve_lx_output(lxc; reprocess=true)


"""
$SIGNATURES

Internal function to resolve a `\\textinput{rpath}` (reads the file and show it after processing).
"""
function resolve_lx_textinput(lxc::LxCom)::String
    rpath = strip(content(lxc.braces[1]))
    return resolve_lx_input_textfile(rpath)
end


"""
$SIGNATURES

Internal function to resolve a `\\literate{rpath}` see [`literate_to_judoc`](@ref).
"""
function resolve_lx_literate(lxc::LxCom)::String
    rpath = strip(content(lxc.braces[1]))
    opath, haschanged = literate_to_judoc(rpath)
    isempty(opath) && return "~~~"*html_err("Literate file matching '$rpath' not found.")*"~~~"
    if !haschanged
        # page has not changed, check if literate is the only source of code
        # and in that case skip eval of all code blocks via freezecode
        if LOCAL_PAGE_VARS["literate_only"].first
            set_var!(LOCAL_PAGE_VARS, "freezecode", true)
        end
    end
    # if haschanged=true then this will be handled cell by cell
    # comparing with cell files following `eval_and_resolve_code`
    return read(opath, String) * EOS
end


"""
$SIGNATURES

Internal function to resolve a `\\figalt{alt}{rpath}` (finds a plot and includes it with alt).
"""
function resolve_lx_figalt(lxc::LxCom)::String
    rpath = strip(content(lxc.braces[2]))
    alt = strip(content(lxc.braces[1]))
    path = resolve_assets_rpath(rpath; canonical=false)
    fdir, fext = splitext(path)
    # there are several cases
    # A. a path with no extension --> guess extension
    # B. a path with extension --> use that
    # then in both cases there can be a relative path set but the user may mean
    # that it's in the subfolder /output/ (if generated by code) so should look
    # both in the relpath and if not found and if /output/ not already the last subdir
    candext = ifelse(isempty(fext), (".png", ".jpeg", ".jpg", ".svg", ".gif"), (fext,))
    for ext ∈ candext
        candpath = fdir * ext
        syspath  = joinpath(PATHS[:folder], split(candpath, '/')...)
        isfile(syspath) && return html_img(candpath, alt)
    end
    # now try in the output dir just in case (provided we weren't already looking there)
    p1, p2 = splitdir(fdir)
    if splitdir(p1)[2] != "output"
        for ext ∈ candext
            candpath = joinpath(p1, "output", p2 * ext)
            syspath  = joinpath(PATHS[:folder], split(candpath, '/')...)
            isfile(syspath) && return html_img(candpath, alt)
        end
    end
    return html_err("image matching '$path' not found")
end


"""
$SIGNATURES

Internal function to resolve a `\\tableinput{header}{rpath}` (finds a csv and includes it with header).
"""
function resolve_lx_tableinput(lxc::LxCom)::String
    rpath = strip(content(lxc.braces[2]))
    header = strip(content(lxc.braces[1]))
    path = resolve_assets_rpath(rpath; canonical=false)
    fdir, fext = splitext(path)
    # copy-paste from resolve_lx_figalt()
    # A. a path with extension --> use that
    # there can be a relative path set but the user may mean
    # that it's in the subfolder /output/ (if generated by code) so should look
    # both in the relpath and if not found and if /output/ not already the last subdir
    syspath  = joinpath(PATHS[:folder], split(path, '/')...)
    if isfile(syspath)
        return csv2html(syspath, header)
    end
    # now try in the output dir just in case (provided we weren't already looking there)
    p1, p2 = splitdir(fdir)
    if splitdir(p1)[2] != "output"
        candpath = joinpath(p1, "output", p2 * fext)
        syspath  = joinpath(PATHS[:folder], split(candpath, '/')...)
        isfile(syspath) && return csv2html(syspath, header)
    end
    return html_err("table matching '$path' not found")
end


"""
$SIGNATURES

Internal function to process an array of strings to markdown table (in one single string).
If header is empty, the first row of the file will be used for header.
"""
function csv2html(path, header)::String
    csvcontent = readdlm(path, ',', String, header=false)
    nrows, ncols = size(csvcontent)
    io = IOBuffer()
    # writing the header
    if ! isempty(header)
        # header provided
        newheader = split(header, ",")
        hs = size(newheader,1)
        hs != ncols && return html_err("header size ($hs) and number of columns ($ncols) do not match")
        write(io, prod("| " * h * " " for h in newheader))
        rowrange = 1:nrows
    else
        # header from csv file
        write(io, prod("| " * csvcontent[1, i] * " " for i in 1:ncols))
        rowrange = 2:nrows
    end
    # writing end of header & header separator
    write(io, "|\n|", repeat( " ----- |", ncols), "\n")
    # writing content
    for i in rowrange
        for j in 1:ncols
            write(io, "| ", csvcontent[i,j], " ")
        end
        write(io, "|\n")
    end
    return md2html(String(take!(io)))
end


"""
$SIGNATURES

Internal function to resolve a `\\file{name}{rpath}` (finds a file and includes it with link name).
Note that while `\\figalt` is tolerant to extensions not being specified, this one is not.
"""
function resolve_lx_file(lxc::LxCom)::String
    rpath = strip(content(lxc.braces[2]))
    name = strip(content(lxc.braces[1]))
    path = resolve_assets_rpath(rpath; canonical=false)
    syspath = joinpath(PATHS[:folder], split(path, '/')...)
    isfile(syspath) && return html_ahref(path, name)
    return html_err("file matching '$path' not found")
end


"""
$SIGNATURES

Dictionary of functions to use for different default latex-like commands. The output of these
commands is inserted "as-is" (without re-processing) in the HTML.
"""
const LXCOM_SIMPLE = LittleDict{String, Function}(
    "\\output" => resolve_lx_output,  # include plain output generated by code
    "\\figalt" => resolve_lx_figalt,  # include a figure (may or may not have been generated)
    "\\file"   => resolve_lx_file,    # include a file
    "\\tableinput" => resolve_lx_tableinput,    # include table from a csv file
    "\\show"   => resolve_lx_show,    # show result of a code block
    )


"""
$SIGNATURES

Same as [`LXCOM_SIMPLE`](@ref) except the output is re-processed before being inserted in the HTML.
"""
const LXCOM_SIMPLE_REPROCESS = LittleDict{String, Function}(
    "\\textoutput" => resolve_lx_textoutput, # include output generated by code and reproc
    "\\textinput"  => resolve_lx_textinput,
    "\\literate"   => resolve_lx_literate,
     )
