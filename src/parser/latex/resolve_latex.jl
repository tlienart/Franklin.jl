#= =========================
Dicts for hyper references
============================ =#

"""
    JD_LOC_EQDICT

Dictionary to keep track of equations that are labelled on a page to allow
references within the page.
"""
const JD_LOC_EQDICT = Dict{UInt, Int}()


"""
    JD_LOC_EQDICT_COUNTER

Counter to keep track of equation numbers as they appear along the page, this
helps with equation referencing.
"""
const JD_LOC_EQDICT_COUNTER = hash("__JD_LOC_EQDICT_COUNTER__")

def_JD_LOC_EQDICT() = begin
    empty!(JD_LOC_EQDICT)
    JD_LOC_EQDICT[JD_LOC_EQDICT_COUNTER] = 0
end


"""
    JD_LOC_BIBREFDICT

Dictionary to keep track of bibliographical references on a page to allow
citation within the page
"""
const JD_LOC_BIBREFDICT = Dict{UInt, String}()

def_JD_LOC_BIBREFDICT() = empty!(JD_LOC_BIBREFDICT)


# convenience constants
const JDLE = JD_LOC_EQDICT
const JDLB = JD_LOC_BIBREFDICT


"""
    form_biblabel(lxc)

Given a `biblabel` command, update `JD_LOC_BIBREFDICT` to keep track of the
reference so that it can be linked with a hyperreference.
"""
function form_biblabel(lxc::LxCom)
    JD_LOC_BIBREFDICT[hash(content(lxc.braces[1]))] = content(lxc.braces[2])
    return "<a name=\"$(hash(content(lxc.braces[1])))\"></a>"
end


"""
    form_href(lxc, d)

Given a latex command such as `\\eqref{abc}`, hash the reference (here `abc`),
check if the given dictionary `d` has an entry corresponding to that hash
and return the appropriate HTML for it.
"""
function form_href(lxc::LxCom, d::Dict{UInt, <:Union{Int, String}};
                    parens="("=>")", refclass="href")

    k = hash(content(lxc.braces[1]))
    haskey(d, k) || return "(<b>??</b>)"
    # construct the link with appropriate parens
    link = "<a href=\"#$k\">$(parens.first)$(d[k])$(parens.second)</a>"
    # encapsulate in a span for potential css-styling
    return "<span class=\"$refclass\">$link</span>"
end


"""
    JD_COMS

Dictionary for special latex commands for which a specific replacement that
refers to context is constructed.
"""
const JD_COMS = Dict{String, Function}(
    "\\eqref" => (λ -> form_href(λ, JDLE; refclass="eqref)")),
    "\\cite"  => (λ -> form_href(λ, JDLB; parens=""=>"", refclass="bibref")),
    "\\citet" => (λ -> form_href(λ, JDLB; parens=""=>"", refclass="bibref")),
    "\\citep" => (λ -> form_href(λ, JDLB; refclass="bibref")),
    "\\biblabel" => form_biblabel,
)


"""
    resolve_lxcom(lxc, lxdefs, inmath)

Take a `LxCom` object `lxc` and try to resolve it. Provided a definition
exists etc, the definition is plugged in then sent forward to be re-parsed
(in case further latex is present).
"""
function resolve_lxcom(lxc::LxCom, lxdefs::Vector{LxDef}, inmath::Bool=false)

    i = findfirst("{", lxc.ss)
    name = isnothing(i) ? lxc.ss : subs(lxc.ss, 1:(first(i)-1))
    # sort special commands where the input depends on context
    haskey(JD_COMS, name) && return JD_COMS[name](lxc)

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
    plug, _ = convert_md(partial, lxdefs, isrecursive=true, isconfig=false,
                         has_mddefs=false)
    return plug
end
