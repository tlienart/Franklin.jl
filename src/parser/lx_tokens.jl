"""
LX_NAME_PAT

Regex to find the name in a new command within a brace block. For example:
    \\newcommand{\\com}[2]{def}
will give as first capture group `\\com`.
"""
const LX_NAME_PAT = r"^\s*(\\[a-zA-Z]+)\s*$"


"""
LX_NARG_PAT

Regex to find the number of argument in a new command (if it is given). For example:
    \\newcommand{\\com}[2]{def}
will give as second capture group `2`. If there are no number of arguments, the second capturing
group will be `nothing`.
"""
const LX_NARG_PAT = r"\s*(\[\s*(\d)\s*\])?\s*"


"""
LX_TOKENS

List of names of latex tokens. (See markdown tokens)
"""
const LX_TOKENS = (:LX_BRACE_OPEN, :LX_BRACE_CLOSE, :LX_COMMAND)


"""
$(TYPEDEF)

Structure to keep track of the definition of a latex command declared via a
`\newcommand{\name}[narg]{def}`.

NOTE: mutable so that we can modify the `from` element to mark it as zero when the command has been
defined in the context of what we're currently parsing.
"""
mutable struct LxDef
    name::String
    narg::Int
    def ::SubString
    # location of the definition > only things that can be mutated via pastdef!
    from::Int
    to  ::Int
end
LxDef(name::String, narg::Int, def::SubString) = LxDef(name, narg, def, 0, 0)

from(lxd::LxDef) = lxd.from
to(lxd::LxDef)   = lxd.to


"""
    pastdef(λ, a)
    pastdef(vλ)

Convenience function to mark a definition as having been defined in the context i.e.: earlier than
any other definition appearing in the current page.
"""
pastdef(λ::LxDef, a::Int) = LxDef(λ.name, λ.narg, λ.def, a, a + (λ.to-λ.from))
function pastdef(vλ::Vector{LxDef})
    # put the past defs far back but preserve order
    vλc = deepcopy(vλ)
    a = -BIG_INT
    for (i, λ) ∈ enumerate(vλc)
        vλc[i] = pastdef(λ, a)
        a = to(vλc[i]) + 1
    end
    return vλc
end


"""
$(TYPEDEF)

A `LxCom` has a similar content as a `Block`, with the addition of the definition and a vector of
brace blocks.
"""
struct LxCom <: AbstractBlock
    ss    ::SubString       # \\command
    lxdef ::Ref{LxDef}      # definition of the command
    braces::Vector{OCBlock} # relevant {...} associated with the command
end
LxCom(ss, def) = LxCom(ss, def, Vector{OCBlock}())
from(lxc::LxCom) = from(lxc.ss)
to(lxc::LxCom) = to(lxc.ss)


"""
$(SIGNATURES)

For a given `LxCom`, retrieve the definition attached to the corresponding `LxDef` via the
reference.
"""
getdef(lxc::LxCom) = getindex(lxc.lxdef).def


"""
$(TYPEDEF)

Convenience structure to keep track of the latex commands and braces.
"""
struct LxContext
    lxcoms::Vector{LxCom}
    lxdefs::Vector{LxDef}
    bblocks::Vector{OCBlock}
end
