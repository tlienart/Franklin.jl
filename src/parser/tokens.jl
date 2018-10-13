abstract type AbstractBlock end

from(β::AbstractBlock) = from(β.ss)
to(β::AbstractBlock)   = to(β.ss)
str(β::AbstractBlock)  = str(β.ss)


"""
    Token <: AbstractBlock

A token `τ::Token` denotes the part of a main source string that we care about
and identified by a symbol `τ.name` (e.g.: `:MATH_ALIGN_OPEN`). Tokens are
typically used in this code to identify delimiters of environments.
See also `Block`, `LxBlock`.
"""
struct Token <: AbstractBlock
    name::Symbol
    ss::SubString
end


"""
    Block === Token

A `Block` has the same content as a `Token`, only the name indicates a segment
of text typically surrounded by an opening and a closing token. This synonym
helps the readability of the code to distinguish delimiters (tokens) from
segments (blocks).
See also `Token`, `LxBlock`.
"""
const Block = Token


hblock(ss::SubString) = Block(:H_BLOCK, ss)


"""
    hinner(block)

For a html block, retrieve the span of what's inside the matching braces.
"""
hblock_content(β::Block) = chop(β.ss, head=2, tail=2)


"""
    OCBlock

Open-Close block, blocks that are defined by an opening token and a closing
token, they may be nested. For instance braces block are formed of an
opening `{` and a closing `}` and they could be nested.
"""
struct OCBlock <: AbstractBlock
    name::Symbol
    ocpair::Pair{Token, Token}
    ss::SubString
end
OCBlock(name, ocpair) = OCBlock(name, ocpair,
    subs(str(ocpair.first), from(ocpair.first), to(ocpair.second)))

otok(ocb::OCBlock) = ocb.ocpair.first
ctok(ocb::OCBlock) = ocb.ocpair.second

"""
    content(ocb)

Return the content of an open-close block (`OCBlock`), for instance the content
of a `{...}` block would be `...`.
"""
function content(ocb::OCBlock)
    return subs(str(ocb.ss), to(otok(ocb))+1, from(ctok(ocb))-1)
end


#=
    FUNCTIONS / CONSTANTS THAT HELP DEFINE TOKENS
=#


"""
    EOS

Convenience symbol to mark the end of the string to parse (helps with corner
cases where a token ends a document without being followed by a space).
"""
const EOS = '⌑'


"""
    SPACER

Convenience list of characters that would correspond to a `\\s` regex.
see also github.com/JuliaLang/julia/blob/master/base/strings/unicode.jl
"""
const SPACER = [' ', '\n', '\t', '\v', '\f', '\r', '\u85', '\ua0', EOS]


"""
    isexactly(refstring, follow, isfollowed)

Forward lookup checking if a sequence of characters matches `refstring` and
is followed (or not followed) by a character out of a list of characters
(`follow`).
It returns
* a number of steps indicating the number of characters to check
* whether there is an offset or not (if it is required to check a following
character or not)
* a function that can be applied on a sequence of character.
"""
function isexactly(refstring::AbstractString, follow=Vector{Char}(),
                   isfollowed=true)
    # number of steps from the start character
    steps = lastindex(refstring) - 1
    # no offset (don't check next character)
    isempty(follow) && return (steps, false, s -> (s == refstring))
    # include next char for verification (--> offset of 1)
    steps += 1
    # verification function
    λ(s) = begin
        check = (s[end] ∈ follow)
        (chop(s) == refstring) && ifelse(isfollowed, check, !check)
    end
    return (steps, true, λ)
end


"""
    α(c, ac)

Check whether `c` is a letter or belongs to `ac`.
"""
α(c::Char, ac=Vector{Char}()) = isletter(c) || (c ∈ ac)


"""
    incrlook(λ)

Syntactic sugar for the incremental look case for which `steps=0` as well as
the `offset`. This is a case where from a start character we lazily accept
the next sequence of characters stopping as soon as one fails to verify `λ(c)`.
"""
incrlook(λ) = (0, false, λ)
