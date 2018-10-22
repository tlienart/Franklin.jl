"""
    LX_TOKENS

List of names of latex tokens. (See markdown tokens)
"""
const LX_TOKENS = [:LX_BRACE_OPEN, :LX_BRACE_CLOSE, :LX_COMMAND]


"""
    islatex(τ)

Convenience function to check if a token is a latex token (see `LX_TOKENS`).
"""
islatex(τ::Token) = τ.name ∈ LX_TOKENS


"""
    LxDef

Structure to keep track of the definition of a latex command declared via a
`\newcommand{\name}[narg]{def}`.
NOTE: mutable so that we can modify the `from` element to mark it as zero when
the command has been defined in the context of what we're currently parsing.
"""
mutable struct LxDef
    name::String
    narg::Int
    def::SubString
    # location of the definition > only things that can be mutated via pastdef!
    from::Int
    to::Int
end
LxDef(name, narg, def) = LxDef(name, narg, def, 0, 0)
from(lxd::LxDef) = lxd.from
to(lxd::LxDef) = lxd.to


"""
    pastdef!(λ)

Convenience function to mark a definition as having been defined in the context
i.e.: earlier than any other definition appearing in the current page.
"""
pastdef!(λ::LxDef) = (λ.to -= λ.from; λ.from = 0; return λ)


"""
    LxCom <: AbstractBlock

A `LxCom` has a similar content as a `Block`, with the addition of the
definition and a vector of brace blocks.
"""
struct LxCom <: AbstractBlock
    ss::SubString           # \\command
    lxdef::Ref{LxDef}       # definition of the command
    braces::Vector{OCBlock} # relevant {...} associated with the command
end
LxCom(ss, def) = LxCom(ss, def, Vector{OCBlock}())
from(lxc::LxCom) = from(lxc.ss)
to(lxc::LxCom) = to(lxc.ss)


"""
    getdef(lxc)

For a given `LxCom`, retrieve the definition attached to the corresponding
`LxDef` via the reference.
"""
getdef(lxc::LxCom) = getindex(lxc.lxdef).def


"""
    LxContext

Convenience structure to keep track of the latex commands and braces.
"""
struct LxContext
    lxcoms::Vector{LxCom}
    lxdefs::Vector{LxDef}
    bblocks::Vector{OCBlock}
end
