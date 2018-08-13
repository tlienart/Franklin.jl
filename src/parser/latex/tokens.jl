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
"""
mutable struct LxDef
    name::String
    narg::Int
    def::String
    # location of the definition
    from::Int
    to::Int
end


"""
    pastdef!(λ)

Convenience function to mark a definition as having been defined in the context
i.e.: earlier than any other definition appearing in the current page.
"""
pastdef!(λ::LxDef) = (shift = λ.from; λ.from = 0; λ.to -= shift; λ)
