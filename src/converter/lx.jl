"""
$(SIGNATURES)

Take a `LxCom` object `lxc` and try to resolve it. Provided a definition exists etc, the definition
is plugged in then sent forward to be re-parsed (in case further latex is present).
"""
function resolve_lxcom(lxc::LxCom, lxdefs::Vector{LxDef}; inmath::Bool=false)::String
    # try to find where the first argument of the command starts (if any)
    i = findfirst("{", lxc.ss)
    # extract the name of the command e.g. \\cite
    name = isnothing(i) ? lxc.ss : subs(lxc.ss, 1:(first(i)-1))

    # sort special commands where the input depends on context (see hyperrefs and inputs)
    haskey(LXCOM_HREF, name)  && return LXCOM_HREF[name](lxc)
    name == "\\input"         && return resolve_lx_input(lxc)
    name ∈ keys(LXCOM_SIMPLE) && return LXCOM_SIMPLE[name](lxc)

    # In subsequent case, whatever the command inserts will be re-parsed (in case the insertion
    # contains further commands or markdown); partial corresponds to what the command corresponds
    # to before re-processing.
    partial = ""

    if name ∈ keys(LXCOM_SIMPLE_REPROCESS)
        partial = LXCOM_SIMPLE_REPROCESS[name](lxc)
    else
        # retrieve the definition attached to the command
        lxdef = getdef(lxc)
        # lxdef = nothing means we're inmath & not found -> let KaTeX deal with it
        isnothing(lxdef) && return lxc.ss
        # lxdef = something -> maybe inmath + found; retrieve & apply
        partial = lxdef
        for (argnum, β) ∈ enumerate(lxc.braces)
            # space sensitive "unsafe" one
            # e.g. blah/!#1 --> blah/blah but note that
            # \command!#1 --> \commandblah and \commandblah would not be found
            partial = replace(partial, "!#$argnum" => content(β))
            # non-space sensitive "safe" one
            # e.g. blah/#1 --> blah/ blah but note that
            # \command#1 --> \command blah and no error.
            partial = replace(partial, "#$argnum" => " " * content(β))
        end
        partial = ifelse(inmath, mathenv(partial), partial) * EOS
    end

    # reprocess (we don't care about jd_vars=nothing)
    plug, _ = convert_md(partial, lxdefs, isrecursive=true, isconfig=false, has_mddefs=false)
    return plug
end

#= ===============
Hyper references
================== =#

"""
PAGE_EQREFS

Dictionary to keep track of equations that are labelled on a page to allow references within the
page.
"""
const PAGE_EQREFS = LittleDict{String, Int}()


"""
PAGE_EQREFS_COUNTER

Counter to keep track of equation numbers as they appear along the page, this helps with equation
referencing. (The `_XC0q` is just a random string to avoid clashes).
"""
const PAGE_EQREFS_COUNTER = "COUNTER_XC0q"


"""
$(SIGNATURES)

Reset the PAGE_EQREFS dictionary.
"""
@inline function def_PAGE_EQREFS!()
    empty!(PAGE_EQREFS)
    PAGE_EQREFS[PAGE_EQREFS_COUNTER] = 0
    return nothing
end


"""
PAGE_BIBREFS

Dictionary to keep track of bibliographical references on a page to allow citation within the page.
"""
const PAGE_BIBREFS = LittleDict{String, String}()

"""
$(SIGNATURES)

Reset the PAGE_BIBREFS dictionary.
"""
def_PAGE_BIBREFS!() = (empty!(PAGE_BIBREFS); nothing)


"""
$(SIGNATURES)

Given a `label` command, replace it with an html anchor.
"""
add_label(λ::LxCom)::String = "<a id=\"$(refstring(strip(content(λ.braces[1]))))\"></a>"


"""
$(SIGNATURES)

Given a `biblabel` command, update `PAGE_BIBREFS` to keep track of the reference so that it
can be linked with a hyperreference.
"""
function add_biblabel(λ::LxCom)::String
    name = refstring(strip(content(λ.braces[1])))
    PAGE_BIBREFS[name] = content(λ.braces[2])
    return "<a id=\"$name\"></a>"
end


"""
$(SIGNATURES)

Given a latex command such as `\\eqref{abc}`, hash the reference (here `abc`), check if the given
dictionary `d` has an entry corresponding to that hash and return the appropriate HTML for it.
"""
function form_href(lxc::LxCom, dname::String; parens="("=>")", class="href")::String
    ct = content(lxc.braces[1])   # "r1, r2, r3"
    refs = strip.(split(ct, ",")) # ["r1", "r2", "r3"]
    names = refstring.(refs)
    nkeys = length(names)
    # construct the partial link with appropriate parens, it will be
    # resolved at the second pass (HTML pass) whence the introduction of {{..}}
    # inner will be "{{href $dn $hr1}}, {{href $dn $hr2}}, {{href $dn $hr3}}"
    # where $hr1 is the hash of r1 etc.
    in = prod("{{href $dname $name}}$(ifelse(i < nkeys, ", ", ""))"
                    for (i, name) ∈ enumerate(names))
    # encapsulate in a span for potential css-styling
    return "<span class=\"$class\">$(parens.first)$in$(parens.second)</span>"
end


"""
LXCOM_HREF

Dictionary for latex commands related to hyperreference for which a specific replacement that
depends on context is constructed.
"""
const LXCOM_HREF = LittleDict{String, Function}(
    "\\eqref"    => (λ -> form_href(λ, "EQR";  class="eqref")),
    "\\cite"     => (λ -> form_href(λ, "BIBR"; parens=""=>"", class="bibref")),
    "\\citet"    => (λ -> form_href(λ, "BIBR"; parens=""=>"", class="bibref")),
    "\\citep"    => (λ -> form_href(λ, "BIBR"; class="bibref")),
    "\\biblabel" => add_biblabel,
    "\\label"    => add_label,
    )


"""
$(SIGNATURES)

Internal function to resolve a relative path to `/assets/` and return the resolved dir as well
as the file name; it also checks that the dir exists. It returns the full path to the file, the
path of the directory containing the file, and the name of the file without extension.
See also [`resolve_lx_input`](@ref).
Note: rpath here is always a UNIX path while the output correspond to SYSTEM paths.
"""
function check_input_rpath(rpath::AS, lang::AS=""; code::Bool=false)::NTuple{3,String}
    # find the full system path to the asset
    fpath = resolve_assets_rpath(rpath; canonical=true, code=code)
    # check if an extension is given, if not, consider it's `.xx` with language `nothing`
    if isempty(splitext(fpath)[2])
        ext, _ = get(CODE_LANG, lang) do
            (".xx", nothing)
        end
        fpath *= ext
    end
    dir, fname = splitdir(fpath)

    # TODO: probably better to not throw an "argumenterror" here but maybe use html_err
    # (though the return type needs to be adjusted accordingly and it shouldn't be propagated)

    # see fill_extension, this is the case where nothing came up
    if endswith(fname, ".xx")
        # try to find a file with the same root and any extension otherwise throw an error
        files = readdir(dir)
        fn = splitext(fname)[1]
        k = findfirst(e -> splitext(e)[1] == fn, files)
        if isnothing(k)
            throw(ArgumentError("Couldn't find a relevant file when trying to " *
                                "resolve an \\input command. (given: $rpath)"))
        end
        fname = files[k]
        fpath = joinpath(dir, fname)
    elseif !isfile(fpath)
        throw(ArgumentError("Couldn't find a relevant file when trying to resolve an \\input " *
                            "command. (given: $rpath)"))
    end
    return fpath, dir, splitext(fname)[1]
end


"""
$(SIGNATURES)

Internal function to read the content of a script file. See also [`resolve_lx_input`](@ref).
"""
function resolve_lx_input_hlcode(rpath::AS, lang::AS)::String
    fpath, = check_input_rpath(rpath; code=true)
    # Read the file while ignoring lines that are flagged with something like `# HIDE`
    _, comsym = CODE_LANG[lang]
    hide     = Regex(raw"(?:^|[^\S\r\n]*?)#(\s)*?(?i)hide(all)?")
    lit_hide = Regex(raw"(?:^|[^\S\r\n]*?)#src")
    hideall  = false
    io_in = IOBuffer()
    open(fpath, "r") do f
        for line ∈ readlines(f)
            # - if there is a \s#\s+HIDE , skip that line
            m  = match(hide, line)
            ml = match(lit_hide, line)
            if all(isnothing, (m, ml))
                write(io_in, line)
                write(io_in, "\n")
            elseif m !== nothing
                # does it have a "all" or not?
                (m.captures[2] === nothing) && continue
                # it does have an "all"
                hideall = true
                break
            end
        end
    end
    hideall && take!(io_in)     # discard the content
    code = String(take!(io_in))
    isempty(code) && return ""
    endswith(code, "\n") && (code = chop(code, tail=1))
    html = html_code(code, lang)
    if LOCAL_PAGE_VARS["showall"].first
        html *= show_res(rpath)
    end
    return html
end


"""
$(SIGNATURES)

Internal function to read the content of a script file and highlight it using `highlight.js`. See
also [`resolve_lx_input`](@ref).
"""
function resolve_lx_input_othercode(rpath::AS, lang::AS)::String
    fpath, = check_input_rpath(rpath, code=true)
    return html_code(read(fpath, String), lang)
end


"""
$SIGNATURES

Internal function to check if a code should suppress the final show.
"""
function check_suppress_show(code::AS)
    scode = strip(code)
    scode[end] == ';' && return true
    # last line ?
    lastline = scode
    i = findlast(e -> e in (';','\n'), scode)
    if !isnothing(i)
        lastline = strip(scode[nextind(scode, i):end])
    end
    startswith(lastline, "@show ")   && return true
    startswith(lastline, "println(") && return true
    startswith(lastline, "print(")   && return true
    return false
end


"""
$SIGNATURES

Internal function to read a result file and show it.
"""
function show_res(rpath::AS)::String
    fpath, = check_input_rpath(rpath; code=true)
    fd, fn = splitdir(fpath)
    stdo   = read(joinpath(fd, "output", splitext(fn)[1] * ".out"), String)
    res    = read(joinpath(fd, "output", splitext(fn)[1] * ".res"), String)
    # check if there's a final `;` or if the last line is a print, println or show
    # in those cases, ignore the result file
    code = strip(read(splitext(fpath)[1] * ".jl", String))
    check_suppress_show(code) && (res = "")
    if !isempty(stdo)
        endswith(stdo, "\n") || (stdo *= "\n")
    end
    res == "nothing" && (res = "")
    isempty(stdo) && isempty(res) && return ""
    return html_div("code_output", html_code(stdo * res))
end

"""
$(SIGNATURES)

Internal function to read the raw output of the execution of a file and display it in a pre block.
See also [`resolve_lx_input`](@ref).
"""
function resolve_lx_input_plainoutput(rpath::AS, reproc::Bool=false; code::Bool=false)::String
    # will throw an error if rpath doesn't exist
    _, dir, fname = check_input_rpath(rpath; code=code)
    out_file = joinpath(dir, "output", fname * ".out")
    # check if the output file exists
    isfile(out_file) || throw(ErrorException("I found an \\input but no relevant output file."))
    # return the content in a pre block (if non empty)
    content = read(out_file, String)
    isempty(content) && return ""
    reproc || return html_code(content)
    return content * EOS
end


"""
$(SIGNATURES)

Internal function to read a file at a specified path and just plug it in. (Corresponds to what a
simple `\\input` command does in LaTeX).
See also [`resolve_lx_textinput`](@ref).
"""
function resolve_lx_input_textfile(rpath::AS)::String
    # find the full system path to the asset
    fpath = resolve_assets_rpath(rpath; canonical=true)
    isempty(splitext(fpath)[2]) && (fpath *= ".md")
    isfile(fpath) || throw(ErrorException("I found a \\textinput but no relevant file."))
    content = read(fpath, String)
    isempty(content) && return ""
    return content * EOS
end


"""
$(SIGNATURES)

Internal function to read a plot outputted by script `rpath`, possibly named with `id`. See also
[`resolve_lx_input`](@ref). The commands `\\fig` and `\\figalt` should be preferred.
"""
function resolve_lx_input_plotoutput(rpath::AS, id::AS="")::String
    # will throw an error if rpath doesn't exist

    _, dir, fname = check_input_rpath(rpath, code=true)
    plt_name = fname * id
    # find a plt in output that has the same root name
    out_path = joinpath(dir, "output")
    isdir(out_path) || throw(ErrorException("I found an input plot but not output dir."))
    out_file = ""
    for (root, _, files) ∈ walkdir(out_path)
        for (f, e) ∈ splitext.(files)
            lc_e = lowercase(e)
            if f == plt_name && lc_e ∈ (".gif", ".jpg", ".jpeg", ".png", ".svg")
                reldir = dir
                if startswith(reldir, PATHS[:folder]) # will usually be the case
                    reldir = reldir[length(PATHS[:folder])+1:end]
                end
                out_file = unixify(joinpath(reldir, "output", plt_name * lc_e))
                break
            end
        end
        out_file == "" || break
    end
    # error if no file found
    out_file != "" || throw(ErrorException("I found an input plot but no relevant output plot."))
    # wrap it in img block
    return html_img(out_file)
end


"""
$(SIGNATURES)

Resolve a command of the form `\\input{code:julia}{path_to_script}` where `path_to_script` is a
valid subpath of `/assets/`. All paths should be expressed relatively to `/assets/` i.e.
`/assets/[subpath]/script.jl`. If things are not in `assets/`, start the path
with `../` to go up one level then go down for instance `../src/pages/script1.jl`.
Forward slashes should also be used on windows.

Different actions can be taken based on the first bracket:
1. `{julia}` or `{code:julia}` will insert the code in the script with appropriate highlighting
2. `{output}` or `{output:plain}` will look for an output file in `/scripts/output/path_to_script` and will just print the content in a non-highlighted code block
3. `{plot}` or `{plot:id}` will look for a displayable image file (gif, png, jp(e)g or svg) in
`/assets/[subpath]/script1` and will add an `img` block as a result. If an `id` is specified,
it will try to find an image with the same root name ending with `id.ext` where `id` can help
identify a specific image if several are generated by the script, typically a number will be used.
"""
function resolve_lx_input(lxc::LxCom)::String
    qualifier = lowercase(strip(content(lxc.braces[1])))  # `code:julia`
    rpath = strip(content(lxc.braces[2])) # [assets]/subpath/script{.jl}

    if occursin(":", qualifier)
        p1, p2 = split(qualifier, ":")
        # code:julia
        if p1 == "code"
            if p2 ∈ keys(CODE_LANG)
                # these are codes for which we know how they're commented and can use the
                # HIDE trick (see HIGHLIGHT and resolve_lx_input_hlcode)
                return resolve_lx_input_hlcode(rpath, p2)
            else
                # another language descriptor, let the user do that with highlights.js
                # note that the HIDE trick will not work here.
                return resolve_lx_input_othercode(rpath, qualifier)
            end
        # output:plain
        elseif p1 == "output"
            if p2 == "plain"
                return resolve_lx_input_plainoutput(rpath, code=true)
            else
                throw(ArgumentError("I found an \\input but couldn't interpret \"$qualifier\"."))
            end
        # plot:id
        elseif p1 == "plot"
            return resolve_lx_input_plotoutput(rpath, p2)
        else
            throw(ArgumentError("I found an \\input but couldn't interpret \"$qualifier\"."))
        end
    else
        if qualifier == "output"
            return resolve_lx_input_plainoutput(rpath; code=true)
        elseif qualifier == "plot"
            return resolve_lx_input_plotoutput(rpath)
        elseif qualifier ∈ ("julia", "fortran", "julia-repl", "matlab", "r", "toml")
            return resolve_lx_input_hlcode(rpath, qualifier)
        else # assume it's another language descriptor, let the user do that with highlights.js
            return resolve_lx_input_othercode(rpath, qualifier)
        end
    end
end
