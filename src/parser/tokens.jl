"""
    AbstractBlock

This is the supertype defining a section of the string into consideration which
can be considered as a "block". For instance, `abc { ... } def` contains one
"braces block" corresponding to the substring `{ ... }`.
All subtypes of AbstractBlock must have a `ss` field corresponding to the
substring associated to the block.
See also `Token`, `Block`, `OCBlock`....
"""
abstract type AbstractBlock end

# convenience functions to locate the substring associated to a block
from(β::AbstractBlock) = from(β.ss)
to(β::AbstractBlock)   = to(β.ss)
str(β::AbstractBlock)  = str(β.ss)


"""
    Token <: AbstractBlock

A token `τ::Token` denotes a part of the source string indicating a region that
may need further processing. It is identified by a symbol `τ.name` (e.g.:
`:MATH_ALIGN_OPEN`). Tokens are typically used in this code to identify
delimiters of environments.
For instance, `abc \$ ... \$ def` contains two tokens `:MATH_A` associated with
the `\$` sign. Together they delimit here an inline math expression.
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
segments (blocks) even though they're effectively defined the same way.
See also `Token`, `LxBlock`.
"""
const Block = Token


"""
    hblock(ss)

Convenience function to mark a substring `ss` as a block with name `:H_BLOCK`.
"""
hblock(ss::SubString) = Block(:H_BLOCK, ss)


"""
    hinner(block)

For a html block, retrieve the span of what's inside the matching braces.
"""
hblock_content(β::Block) = chop(β.ss, head=2, tail=2)


"""
    OCBlock

Open-Close block, blocks that are defined by an opening `Token` and a closing
`Token`, they may be nested. For instance braces block are formed of an
opening `{` and a closing `}` and could be nested.
"""
struct OCBlock <: AbstractBlock
    name::Symbol
    ocpair::Pair{Token, Token}
    ss::SubString
end


"""
    OCBlock(name, ocpair)

Shorthand constructor to instantiate an `OCBlock` inferring the associated
substring from the `ocpair` (since it's the substring in between the tokens).
"""
OCBlock(η, ω) = OCBlock(η, ω, subs(str(ω.first), from(ω.first), to(ω.second)))


"""
    otok(ocb)

Convenience function to retrieve the opening token of an `OCBlock`.
"""
otok(ocb::OCBlock) = ocb.ocpair.first


"""
    otok(ocb)

Convenience function to retrieve the closing token of an `OCBlock`.
"""
ctok(ocb::OCBlock) = ocb.ocpair.second


"""
    content(ocb)

Convenience function to return the content of an open-close block (`OCBlock`),
for instance the content of a `{...}` block would be `...`.
"""
function content(ocb::OCBlock)
    s = str(ocb.ss) # this does not allocate
    cfrom = nextind(s, to(otok(ocb)))
    cto = prevind(s, from(ctok(ocb)))
    return subs(s, cfrom, cto)
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
is followed (or not followed if `isfollowed==false`) by a character out of a
list of characters (`follow`).
It returns
1. a number of steps indicating the number of characters to check,
2. whether there is an offset or not (if it is required to check a following
character or not),
3. a function that can be applied on a sequence of character.
"""
function isexactly(refstring::AbstractString, follow=Vector{Char}(),
                   isfollowed=true)
    # number of steps from the start character
    steps = prevind(refstring, lastindex(refstring))
    # no offset (don't check next character)
    isempty(follow) && return (steps, false, s -> (s == refstring))
    # include next char for verification (--> offset of 1)
    steps = nextind(refstring, steps)
    # verification function
    λ(s) = begin
        check = (s[end] ∈ follow)
        (chop(s) == refstring) && ifelse(isfollowed, check, !check)
    end

    return (steps, true, λ)
end


"""
    α(c)

Check whether `c` is a letter.
"""
α(c::Char) = isletter(c)


"""
    α(c, ac)

Check whether `c` is in a vector of characters `ac`.
"""
α(c::Char, ac::Vector{Char}) = (c ∈ ac)


"""
    incrlook(λ)

Syntactic sugar for the incremental look case for which `steps=0` as well as
the `offset`. This is a case where from a start character we lazily accept
the next sequence of characters stopping as soon as a character fails to verify
`λ(c)`.
See also `isexactly`.
"""
incrlook(λ) = (0, false, λ)
