"""
    resolve_lxcom(lxc, lxdefs; inmath)

Take a `LxCom` object `lxc` and try to resolve it. Provided a definition exists etc, the definition
is plugged in then sent forward to be re-parsed (in case further latex is present).
"""
function resolve_lxcom(lxc::LxCom, lxdefs::Vector{LxDef}; inmath=false)

    i = findfirst("{", lxc.ss)
    # extract the name of the command e.g. \\cite
    name = isnothing(i) ? lxc.ss : subs(lxc.ss, 1:(first(i)-1))

    # sort special commands where the input depends on context
    haskey(JD_REF_COMS, name) && return JD_REF_COMS[name](lxc)

    (name == "\\input") && return resolve_input(lxc)

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
const JD_LOC_EQDICT_COUNTER = randstring(JD_LEN_RANDSTRING+1)

def_JD_LOC_EQDICT() = begin
    empty!(JD_LOC_EQDICT)
    JD_LOC_EQDICT[JD_LOC_EQDICT_COUNTER] = 0
end


"""
    JD_LOC_BIBREFDICT

Dictionary to keep track of bibliographical references on a page to allow citation within the page.
"""
const JD_LOC_BIBREFDICT = Dict{String, String}()

def_JD_LOC_BIBREFDICT() = empty!(JD_LOC_BIBREFDICT)


"""
    form_biblabel(lxc)

Given a `biblabel` command, update `JD_LOC_BIBREFDICT` to keep track of the reference so that it
can be linked with a hyperreference.
"""
function form_biblabel(λ::LxCom)
    name = refstring(strip(content(λ.braces[1])))
    JD_LOC_BIBREFDICT[name] = content(λ.braces[2])
    return "<a id=\"$name\"></a>"
end


"""
    form_href(lxc, d)

Given a latex command such as `\\eqref{abc}`, hash the reference (here `abc`), check if the given
dictionary `d` has an entry corresponding to that hash and return the appropriate HTML for it.
"""
function form_href(lxc::LxCom, dname::String; parens="("=>")", class="href")

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
    resolve_input(lxc)

Resolve a command of the form `\\input{julia}{script.jl}` by replacing it with a qualified guarded
code block (allowing syntax highlighting). If the first brackets are empty, it will be a simple
unqualified code-block.
"""
function resolve_input(lxc::LxCom)
    qual  = strip(content(lxc.braces[1])) # julia
    fname = strip(content(lxc.braces[2])) # script1.jl
    # NOTE: based on extension, could have different actions
    # --> .jl, .py, etc should write a qualified guarded code block
    # --> .txt and by default, should write an unqualified code block
    # --> .table or other special extensions could directly format into tables?
    isfile(fname) || throw(ArgumentError("I found an \\input command but couldn't find $fname."))

    io = IOBuffer()
    open(fname, "r") do f
        for line ∈ readlines(f)
             # - if there is a \s#\s+HIDE , skip that line
             match(r"\s#(\s)*?[hH][iI][dD][eE]", line) === nothing || continue
             write(io, line)
             write(io, "\n")
        end
    end
    qual_lc = lowercase(qual)
    class = ifelse(isempty(qual_lc), "", "class=$qual_lc")

    # NOTE: here our own syntax highlighting could be done for recognised languages
    return "<pre><code $class>$(strip(String(take!(io))))</code></pre>"
end
