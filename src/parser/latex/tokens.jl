"""
LX_TOKENS

List of names of latex tokens. (See markdown tokens)
"""
const LX_TOKENS = (:LX_BRACE_OPEN, :LX_BRACE_CLOSE, :LX_COMMAND)


"""
$(TYPEDEF)

Structure to keep track of the definition of a latex command declared via a
`\\newcommand{\\name}[narg]{def}` or of an environment via
`\\newenvironment{name}[narg]{pre}{post}`.
The parametric type depends on the definition type, for a command it will be
a SubString (<: AbstractString), for an environment it will be a Pair of
SubString (corresponding to pre-post).
"""
struct LxDef{T}
    name::String
    narg::Int
    def ::T
    # location of the definition
    from::Int
    to  ::Int
end
# if offset unspecified, start from basically -∞ (configs etc)
function LxDef(name::AS, narg::Int, def)
    o = FD_ENV[:OFFSET_LXDEFS] += 5  # precise offset doesn't matter
    LxDef(string(name), narg, def, o, o + 3) # just forward a bit
end

from(lxd::LxDef) = lxd.from
to(lxd::LxDef)   = lxd.to

"""
pastdef(λ)

Convenience function to return a copy of a definition indicated as having
already been earlier in the context i.e.: earlier than any other definition
appearing in the current chunk.
"""
pastdef(λ::LxDef) = LxDef(λ.name, λ.narg, λ.def)

"""
$(TYPEDEF)

Super type for `LxCom` and `LxEnv`.
"""
abstract type LxObj <: AbstractBlock end

"""
$(TYPEDEF)

A `LxCom` has a similar content as a `Block`, with the addition of the definition and a vector of brace blocks.
"""
struct LxCom <: LxObj
    ss    ::SubString                 # \\command
    lxdef ::Union{Nothing,Ref{LxDef}} # definition of the command
    braces::Vector{OCBlock}           # relevant {...} with the command
end
LxCom(ss, def) = LxCom(ss, def, Vector{OCBlock}())


"""
$TYPEDEF

A `LxEnv` is similar to a `LxCom` but for an environment.

    `\\begin{aaa} ... \\end{aaa}`
    `\\begin{aaa}{opt1}{opt2} ... \\end{aaa}`
"""
struct LxEnv <: LxObj
    ss    ::SubString
    lxdef ::Union{Nothing,Ref{LxDef}}
    braces::Vector{OCBlock}
    ocpair::Pair{Token,Token}
end
LxEnv(ss, def, ocp) = LxCom(ss, def, Vector{OCBlock}(), ocp)

"""
$SIGNATURES

Content of an `LxEnv` block.

    `\\begin{aaa}{opt1} XXX \end{aaa}` --> ` XXX `
"""
function content(lxe::LxEnv)
    s = str(ocb.ss)
    cfrom = nextind(s, to(ocpair.first))
    if !isempty(braces)
        cfrom = nextind(s, to(braces[end]))
    end
    cto = prevind(s, from(ocpair.second))
    return subs(s, cfrom, cto)
end


"""
$SIGNATURES

For a given `LxObj`, retrieve the definition attached to the corresponding `LxDef` via the
reference.
"""
function getdef(lxo::LxObj)::Union{Nothing,AS}
    isnothing(lxo.lxdef) && return nothing
    return getindex(lxo.lxdef).def
end

"""
$SIGNATURES

For a given `LxObj`, retrieve the name of the object via the reference.
Example: `\\cite` --> `cite` or `\\begin{aaa}` --> `aaa`.
"""
function getname(lxo::LxObj)::String
    if isnothing(lxo.lxdef)
        s = String(lxo.ss)
        j = findfirst('{', s)
        return lxo.ss[2:prevind(s, j)]
    end
    return String(getindex(lxo.lxdef).name)[2:end]
end
