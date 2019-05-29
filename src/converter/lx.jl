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

Given a `biblabel` command, update `JD_LOC_BIBREFDICT` to keep track of the reference so that it
can be linked with a hyperreference.
"""
function form_biblabel(λ::LxCom)::String
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
    "\\biblabel" => form_biblabel,
    )


"""
$(SIGNATURES)

Internal function to check that a given filename exists in `JD_PATH[:scripts]`. See also
[`resolve_input`](@ref).
"""
function check_input_fname(fname::AbstractString)::String
    fp = joinpath(JD_PATHS[:scripts], fname)
    isfile(fp) || throw(ArgumentError("Couldn't find file $fp when trying to resolve an \\input."))
    return fp
end

"""
$(SIGNATURES)

Internal function to read the content of a script file and highlight it using `Highlights.jl`.
See also [`resolve_input`](@ref).
"""
function resolve_input_hlcode(fname::AbstractString, lang::AbstractString;
                              use_hl::Bool=true)::String
    fp = check_input_fname(fname)
    # Read the file while ignoring lines that are flagged with something like `# HIDE`
    comsym, lexer = HIGHLIGHT[lang]
    hide = Regex("\\s$(comsym)(\\s)*?(?i)hide")
    io_in = IOBuffer()
    open(fp, "r") do f
        for line ∈ readlines(f)
             # - if there is a \s#\s+HIDE , skip that line
             match(hide, line) === nothing || continue
             write(io_in, line)
             write(io_in, "\n")
        end
    end
    if use_hl
        io_out = IOBuffer()
        highlight(io_out, MIME("text/html"), String(take!(io_in)), lexer)
        return String(take!(io_out))
    end
    return "<pre><code class=\"language-$lang\">$(String(take!(io_in)))</code></pre>"
end

"""
$(SIGNATURES)

Internal function to read the content of a script file and highlight it using `highlight.js`. See
also [`resolve_input`](@ref).
"""
function resolve_input_othercode(fname::AbstractString, lang::AbstractString)::String
    fp = check_input_fname(fname)
    return "<pre><code class=\"language-$lang\">$(read(fp, String))</code></pre>"
end

"""
$(SIGNATURES)

Internal function to read the raw output of the execution of a file and display it in a pre block.
See also [`resolve_input`](@ref).
"""
function resolve_input_plainoutput(fname::AbstractString)::String
    # will throw an error if fname doesn't exist as a script
    check_input_fname(fname)
    # find a file in output that has the same root name
    d, fn = splitdir(fname)
    fn, _ = splitext(fn)
    outdir = joinpath(JD_PATHS[:scripts], "output", d)
    isdir(outdir) || throw(ErrorException("I found an input command but not $outdir."))
    fp = ""
    for (root, _, files) ∈ walkdir(outdir)
        for (f, e) ∈ splitext.(files)
            if fn == f
                fp = joinpath(root, f * e)
                break
            end
        end
        fp == "" || break
    end
    fp != "" || throw(ErrorException("I found an input command but not a relevant output file."))
    return "<pre><code>$(read(fp, String))</code></pre>"
end

"""
$(SIGNATURES)

Internal function to read a plot outputted by script `fname`, possibly named with `id`. See also
[`resolve_input`](@ref).
"""
function resolve_input_plotoutput(fname::AbstractString, id::AbstractString="")::String
    fp = check_input_fname(fname)
    # find an img in output that has the same root name
    d, fn = splitdir(fname)
    fn, _ = splitext(fn)
    fn *= id
    outdir = joinpath(JD_PATHS[:scripts], "output", d)
    isdir(outdir) || throw(ErrorException("I found an input command but not $outdir."))
    fp = ""
    for (root, _, files) ∈ walkdir(outdir)
        for (f, e) ∈ splitext.(files)
            lc_e = lowercase(e)
            if fn == f && lc_e ∈ (".gif", ".jpg", ".jpeg", ".png", ".svg")
                fp = f * lc_e
                break
            end
        end
        fp == "" || break
    end
    fp != "" || throw(ErrorException("I found an input command but not a relevant output plot."))
    return "<img src=\"/assets/scripts/output/$(joinpath(d, fp))\" id=\"judoc-out-plot\"/>"
end

"""
$(SIGNATURES)

Resolve a command of the form `\\input{code:julia}{path_to_script}` where `path_to_script` is a
valid subpath of `/scripts/`. All paths should be expressed relatively to `scripts/` so for
instance `script1.jl` or `folder1/script1.jl`.

Different actions can be taken based on the first bracket:
1. `{julia}` or `{code:julia}` will insert the code in the script with appropriate highlighting
2. `{output}` or `{output:plain}` will look for an output file in `/scripts/output/path_to_script` and will just print the content in a non-highlighted code block
3. `{plot}` or `{plot:id}` will look for a displayable image file (gif, png, jp(e)g or svg) in
`/scripts/output/path_to_script` and will add an `img` block as a result. If an `id` is specified,
it will try to find an image with the same root name ending with `id.ext` where `id` can help
identify a specific image if several are generated by the script, typically a number will be used.
"""
function resolve_input(lxc::LxCom)::String
    isdir(JD_PATHS[:scripts]) || throw(ExceptionError("I found an \\input command but the " *
                                        "folder `scripts/` doesn't exist. Scripts corresponding " *
                                        "to \\input commands must be in this folder."))
    qual  = lowercase(strip(content(lxc.braces[1]))) # `code:julia`
    fname = strip(content(lxc.braces[2])) # `scripts/script1.jl`

    if occursin(":", qual)
        p1, p2 = split(qual, ":")
        if p1 == "code"
            if p2 ∈ ("julia", "fortran", "julia-repl", "matlab", "r", "toml")
                return resolve_input_hlcode(fname, p2; use_hl=false)
            else # another language descriptor, let the user do that with highlights.js
                return resolve_input_othercode(fname, qual)
            end
        elseif p1 == "output"
            if p2 == "plain"
                return resolve_input_plainoutput(fname)
            # elseif p2 == "table"
            #     return resolve_input_tableoutput(fname)
            else
                throw(ArgumentError("I found an \\input command but couldn't interpret \"$qual\"."))
            end
        elseif p1 == "plot"
            return resolve_input_plotoutput(fname, p2)
        else
            throw(ArgumentError("I found an \\input command but couldn't interpret \"$qual\"."))
        end
    else
        if qual == "output"
            return resolve_input_plainoutput(fname)
        elseif qual == "plot"
            return resolve_input_plotoutput(fname)
        # elseif qual == "table"
        #     return resolve_input_tableoutput(fname)
        elseif qual ∈ ("julia", "fortran", "julia-repl", "matlab", "r", "toml")
            return resolve_input_hlcode(fname, qual; use_hl=false)
        else # assume it's another language descriptor, let the user do that with highlights.js
            return resolve_input_othercode(fname, qual)
        end
    end
end
