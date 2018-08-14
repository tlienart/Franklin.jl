"""
    Token

A token `τ::Token` denotes the part of a main source string that we care about
covering the range `τ.from:τ.to` and identified by a symbol `τ.name` (e.g.:
`:MATH_ALIGN_OPEN`). Tokens are typically used in this code to identify
delimiters of environments.
"""
struct Token
    name::Symbol
    from::Int
    to::Int
end
# convenience constructor for single-char token such as `{`
Token(name::Symbol, loc::Int) = Token(name, loc, loc)


"""
    Block

A block has the same content as a token, only the name indicates a segment of
text typically surrounded by an opening and a closing token. This synonym helps
the readability of the code to distinguish delimiters (tokens) from segments
(blocks).
"""
const Block = Token


"""
    remain(i, j)

Convenience constructor for a `:REMAIN` block (blocks that may need further
parsing)
"""
remain(i::Int, j::Int) = Block(:REMAIN, i, j)


"""
    braces(from, to)

Convenience constructor for a `:LXB` block (latex brackets block i.e. an
opening brace, the matching closing brace and the span between.)
"""
braces(from::Int, to::Int) = Block(:LXB, from, to)


"""
    hblock(from, to)

Convenience constructor for a `:H_BLOCK` block (html block {{...}}).
"""
hblock(from::Int, to::Int) = Block(:H_BLOCK, from, to)


"""
    brange(block)

For a brace block, retrieve the span of what's inside the matching braces.
"""
brange(block::Block) = block.from+1:block.to-1


"""
    hrange(block)

For a hblock, retrieve the span of what's inside the matching braces.
"""
hrange(block::Block) = block.from+2:block.to-2


"""
    span_after(blocks, i)

Given a list of blocks `blocks` and a block index `i` give the span between
the ith block and the (i+1)th block.
"""
function span_after(blocks::Vector{Block}, i::Int, eos::Int=0)
    i == length(blocks) && return (blocks[i].to + 1, eos)
    return (blocks[i].to + 1, blocks[i+1].from - 1)
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
function isexactly(refstring::String, follow=Vector{Char}(), isfollowed=true)
    # number of steps from the start character
    steps = length(refstring) - 1
    # no offset (don't check next character)
    isempty(follow) && return (steps, false, s -> s==refstring)
    # include next char for verification (--> offset of 1)
    steps += 1
    # verification function
    λ = s -> (s[1:end-1] == refstring) &&
                (isfollowed ? s[end] ∈ follow : s[end] ∉ follow)
    return (steps, true, λ)
end


"""
    α(c)

Syntactic sugar for `isalpha(c)`.
"""
α(c::Char) = isalpha(c)


"""
    incrlook(λ)

Syntactic sugar for the incremental look case for which `steps=0` as well as
the `offset`. This is a case where from a start character we lazily accept
the next sequence of characters stopping as soon as one fails to verify `λ(c)`.
"""
incrlook(λ) = (0, false, λ)
