"""
LX_TOKENS

List of names of latex tokens. (See markdown tokens)
"""
const LX_TOKENS = (:LX_BRACE_OPEN, :LX_BRACE_CLOSE, :LX_COMMAND)


"""
$(TYPEDEF)

Structure to keep track of the definition of a latex command declared via a
`\newcommand{\name}[narg]{def}`.
"""
struct LxDef
    name::String
    narg::Int
    def ::AS
    # location of the definition
    from::Int
    to  ::Int
end
# if offset unspecified, start from basically -∞ (configs etc)
function LxDef(name::String, narg::Int, def::AS)
    o = FD_ENV[:OFFSET_LXDEFS] += 5  # precise offset doesn't matter, jus
    LxDef(name, narg, def, o, o + 3) # just forward a bit
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

A `LxCom` has a similar content as a `Block`, with the addition of the definition and a vector of brace blocks.
"""
struct LxCom <: AbstractBlock
    ss    ::SubString                 # \\command
    lxdef ::Union{Nothing,Ref{LxDef}} # definition of the command
    braces::Vector{OCBlock}           # relevant {...} with the command
end
LxCom(ss, def)   = LxCom(ss, def, Vector{OCBlock}())
from(lxc::LxCom) = from(lxc.ss)
to(lxc::LxCom)   = to(lxc.ss)


"""
For a given `LxCom`, retrieve the definition attached to the corresponding
`LxDef` via the reference.
"""
function getdef(lxc::LxCom)::Union{Nothing,AS}
    if isnothing(lxc.lxdef)
        return nothing
    end
    return getindex(lxc.lxdef).def
end

"""
For a given `LxCom`, retrieve the name of the command via the reference.
Example: `\\cite` --> `cite`.
"""
function getname(lxc::LxCom)::String
    if isnothing(lxc.lxdef)
        s = String(lxc.ss)
        j = findfirst('{', s)
        return lxc.ss[2:prevind(s, j)]
    end
    return String(getindex(lxc.lxdef).name)[2:end]
end
# XXX if nothing lxc.lxdef then extract from lxc.ss but extract before {}
