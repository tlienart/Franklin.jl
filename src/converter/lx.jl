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
    haskey(JD_REF_COMS, name) && return JD_REF_COMS[name](lxc)
    (name == "\\input")       && return resolve_input(lxc)
    (name == "\\output")      && return resolve_output(lxc)

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

    # reprocess (we don't care about jd_vars=nothing)
    plug, _ = convert_md(partial, lxdefs, isrecursive=true,
                         isconfig=false, has_mddefs=false)
    return plug
end

#= ===============
Hyper references
================== =#

"""
JD_LOC_EQDICT

Dictionary to keep track of equations that are labelled on a page to allow references within the
page.
"""
const JD_LOC_EQDICT = Dict{String, Int}()


"""
JD_LOC_EQDICT_COUNTER

Counter to keep track of equation numbers as they appear along the page, this helps with equation
referencing.
"""
const JD_LOC_EQDICT_COUNTER = "COUNTER_XC0q"

"""
$(SIGNATURES)

Reset the JD_LOC_EQDICT dictionary.
"""
@inline function def_JD_LOC_EQDICT!()
    empty!(JD_LOC_EQDICT)
    JD_LOC_EQDICT[JD_LOC_EQDICT_COUNTER] = 0
    return nothing
end


"""
JD_LOC_BIBREFDICT

Dictionary to keep track of bibliographical references on a page to allow citation within the page.
"""
const JD_LOC_BIBREFDICT = Dict{String, String}()

"""
$(SIGNATURES)

Reset the JD_LOC_BIBREFDICT dictionary.
"""
def_JD_LOC_BIBREFDICT!() = (empty!(JD_LOC_BIBREFDICT); nothing)


"""
$(SIGNATURES)

Given a `label` command, replace it with an html anchor.
"""
add_label(λ::LxCom)::String = "<a id=\"$(refstring(strip(content(λ.braces[1]))))\"></a>"


"""
$(SIGNATURES)

Given a `biblabel` command, update `JD_LOC_BIBREFDICT` to keep track of the reference so that it
can be linked with a hyperreference.
"""
function add_biblabel(λ::LxCom)::String
    name = refstring(strip(content(λ.braces[1])))
    JD_LOC_BIBREFDICT[name] = content(λ.braces[2])
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
JD_REF_COMS

Dictionary for latex commands related to hyperreference for which a specific replacement that
depends on context is constructed.
"""
const JD_REF_COMS = Dict{String, Function}(
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
See also [`resolve_input`](@ref).
"""
function check_input_rpath(rpath::AbstractString, lang::AbstractString="")::NTuple{3,String}
    fpath = resolve_assets_rpath(rpath)
    if isempty(splitext(fpath)[2])
        ext = get(LANG_EXT, lang) do
            ".xx"
        end
        fpath *= ext
    end
    dir, fname = splitdir(fpath)

    # see fill_extension, this is the case where nothing came up
    if endswith(fname, ".xx")
        # try to find a file with whatever extension otherwise throw an error
        files = readdir(dir)
        fn = splitext(fname)[1]
        k = findfirst(e -> splitext(e)[1] == fn, files)
        k === nothing && throw(ArgumentError("Couldn't find a relevant file when trying to " *
                                             "resolve an \\input command. (given: $rpath)"))
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

Internal function to read the content of a script file and highlight it using either highlight.js
or `Highlights.jl`. See also [`resolve_input`](@ref).
"""
function resolve_input_hlcode(rpath::AbstractString, lang::AbstractString;
                              use_hl::Bool=false)::String
    fpath, _, _ = check_input_rpath(rpath)
    # Read the file while ignoring lines that are flagged with something like `# HIDE`
    comsym, lexer = HIGHLIGHT[lang]
    hide = Regex("\\s$(comsym)(\\s)*?(?i)hide")
    io_in = IOBuffer()
    open(fpath, "r") do f
        for line ∈ readlines(f)
             # - if there is a \s#\s+HIDE , skip that line
             match(hide, line) === nothing || continue
             write(io_in, line)
             write(io_in, "\n")
        end
    end
    code = String(take!(io_in))
    endswith(code, "\n") && (code = chop(code, tail=1))
    if use_hl
        io_out = IOBuffer()
        highlight(io_out, MIME("text/html"), code, lexer)
        return String(take!(io_out))
    end
    return "<pre><code class=\"language-$lang\">$code</code></pre>"
end


"""
$(SIGNATURES)

Internal function to read the content of a script file and highlight it using `highlight.js`. See
also [`resolve_input`](@ref).
"""
function resolve_input_othercode(rpath::AbstractString, lang::AbstractString)::String
    fpath, _, _ = check_input_rpath(rpath)
    return "<pre><code class=\"language-$lang\">$(read(fpath, String))</code></pre>"
end


"""
$(SIGNATURES)

Internal function to read the raw output of the execution of a file and display it in a pre block.
See also [`resolve_input`](@ref).
"""
function resolve_input_plainoutput(rpath::AbstractString)::String
    # will throw an error if rpath doesn't exist
    _, dir, fname = check_input_rpath(rpath)
    out_file = joinpath(dir, "output", fname * ".out")
    # check if the output file exists
    isfile(out_file) || throw(ErrorException("I found an \\input but no relevant output file."))
    # return the content in a pre block
    return "<pre><code>$(read(out_file, String))</code></pre>"
end


"""
$(SIGNATURES)

Internal function to read a plot outputted by script `rpath`, possibly named with `id`. See also
[`resolve_input`](@ref).
"""
function resolve_input_plotoutput(rpath::AbstractString, id::AbstractString="")::String
    # will throw an error if rpath doesn't exist
    _, dir, fname = check_input_rpath(rpath)
    plt_name = fname * id
    # relative dir /assets/...
    reldir = normpath(joinpath("/assets/", dirname(rpath)))
    # find a plt in output that has the same root name
    out_path = joinpath(dir, "output")
    isdir(out_path) || throw(ErrorException("I found an input plot but not output dir."))
    out_file = ""
    for (root, _, files) ∈ walkdir(out_path)
        for (f, e) ∈ splitext.(files)
            lc_e = lowercase(e)
            if f == plt_name && lc_e ∈ (".gif", ".jpg", ".jpeg", ".png", ".svg")
                out_file = joinpath(reldir, "output", plt_name * lc_e)
                break
            end
        end
        out_file == "" || break
    end
    # error if no file found
    out_file != "" || throw(ErrorException("I found an input plot but no relevant output plot."))
    # wrap it in img block
    return "<img src=\"$(out_file)\" id=\"judoc-out-plot\"/>"
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
function resolve_input(lxc::LxCom)::String
    qualifier = lowercase(strip(content(lxc.braces[1])))  # `code:julia`
    rpath = strip(content(lxc.braces[2])) # [assets]/subpath/script{.jl}

    if occursin(":", qualifier)
        p1, p2 = split(qualifier, ":")
        # code:julia
        if p1 == "code"
            if p2 ∈ ("julia", "fortran", "julia-repl", "matlab", "r", "toml")
                return resolve_input_hlcode(rpath, p2; use_hl=false)
            else # another language descriptor, let the user do that with highlights.js
                return resolve_input_othercode(rpath, qualifier)
            end
        # output:plain
        elseif p1 == "output"
            if p2 == "plain"
                return resolve_input_plainoutput(rpath)
            # elseif p2 == "table"
            #     return resolve_input_tableoutput(rpath)
            else
                throw(ArgumentError("I found an \\input but couldn't interpret \"$qualifier\"."))
            end
        # plot:id
        elseif p1 == "plot"
            return resolve_input_plotoutput(rpath, p2)
        else
            throw(ArgumentError("I found an \\input but couldn't interpret \"$qualifier\"."))
        end
    else
        if qualifier == "output"
            return resolve_input_plainoutput(rpath)
        elseif qualifier == "plot"
            return resolve_input_plotoutput(rpath)
        # elseif qualifier == "table"
        #     return resolve_input_tableoutput(rpath)
        elseif qualifier ∈ ("julia", "fortran", "julia-repl", "matlab", "r", "toml")
            return resolve_input_hlcode(rpath, qualifier; use_hl=false)
        else # assume it's another language descriptor, let the user do that with highlights.js
            return resolve_input_othercode(rpath, qualifier)
        end
    end
end


"""
$SIGNATURES

Internal function to resolve a `\\output{rpath}` (finds the output and shows it).
"""
function resolve_output(lxc::LxCom)::String
    rpath = strip(content(lxc.braces[1])) # [assets]/subpath/script{.jl}
    return resolve_input_plainoutput(rpath)
end
