"""
$(TYPEDEF)

This is the supertype defining a section of the string into consideration which can be considered
as a "block". For instance, `abc { ... } def` contains one braces block corresponding to the
substring `{ ... }`. All subtypes of AbstractBlock must have a `ss` field corresponding to the
substring associated to the block. See also [`Token`](@ref), [`OCBlock`](@ref).
"""
abstract type AbstractBlock end

# convenience functions to locate the substring associated to a block
from(β::AbstractBlock) = from(β.ss)
to(β::AbstractBlock)   = to(β.ss)
str(β::AbstractBlock)  = str(β.ss)


"""
$(TYPEDEF)

A token `τ::Token` denotes a part of the source string indicating a region that may need further
processing. It is identified by a symbol `τ.name` (e.g.: `:MATH_ALIGN_OPEN`). Tokens are typically
used in this code to identify delimiters of environments. For instance, `abc \$ ... \$ def`
contains two tokens `:MATH_A` associated with the `\$` sign. Together they delimit here an inline
math expression. See also [`LxBlock`](@ref).
"""
struct Token <: AbstractBlock
    name::Symbol
    ss::SubString
end


"""
$(TYPEDEF)

Open-Close block, blocks that are defined by an opening `Token` and a closing `Token`, they may be
nested. For instance braces block are formed of an opening `{` and a closing `}` and could be
nested.
"""
struct OCBlock <: AbstractBlock
    name::Symbol
    ocpair::Pair{Token,Token}
    ss::SubString
end


"""
$(SIGNATURES)

Shorthand constructor to instantiate an `OCBlock` inferring the associated substring from the
`ocpair` (since it's the substring in between the tokens).
"""
OCBlock(η::Symbol, ω::Pair{Token,Token}) =
    OCBlock(η, ω, subs(str(ω.first), from(ω.first), to(ω.second)))


"""
$(SIGNATURES)

Convenience function to retrieve the opening token of an `OCBlock`.
"""
otok(ocb::OCBlock)::Token = ocb.ocpair.first


"""
$(SIGNATURES)

Convenience function to retrieve the closing token of an `OCBlock`.
"""
ctok(ocb::OCBlock)::Token = ocb.ocpair.second


"""
$(SIGNATURES)

Convenience function to return the content of an open-close block (`OCBlock`), for instance the
content of a `{...}` block would be `...`.
"""
function content(ocb::OCBlock)::SubString
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

Convenience symbol to mark the end of the string to parse (helps with corner cases where a token
ends a document without being followed by a space).
"""
const EOS = '⌑'


"""
SPACER

Convenience list of characters that would correspond to a `\\s` regex. see also
https://github.com/JuliaLang/julia/blob/master/base/strings/unicode.jl.
"""
const SPACER = [' ', '\n', '\t', '\v', '\f', '\r', '\u85', '\ua0', EOS]


"""
$(SIGNATURES)

Forward lookup checking if a sequence of characters matches `refstring` and is followed (or not
followed if `isfollowed==false`) by a character out of a list of characters (`follow`).
It returns

1. a number of steps indicating the number of characters to check,
2. whether there is an offset or not (if it is required to check a following character or not),
3. a function that can be applied on a sequence of character.

# Example

```julia-repl
julia> (s, b, f) = isexactly("aabbc", "d", isfollowed=false);
julia> f("aabbcd")
false
julia> f("aabbce")
true
julia> s
5
```
"""
function isexactly(refstring::AbstractString, follow=Vector{Char}(),
                   isfollowed=true)::Tuple{Int,Bool,Function}
    # number of steps from the start character
    steps = prevind(refstring, lastindex(refstring))
    # no offset (don't check next character)
    isempty(follow) && return (steps, false, s -> (s == refstring))
    # include next char for verification (--> offset of 1)
    steps = nextind(refstring, steps)
    # verification function
    λ(s) = (chop(s) == refstring) && !xor(isfollowed, s[end] ∈ follow)
    return (steps, true, λ)
end


"""
$(SIGNATURES)

Check whether `c` is a letter or is in a vector of character `ac`.
"""
α(c::Char, ac::Vector{Char}=Vector{Char}())::Bool = isletter(c) || (c ∈ ac)


"""
$(SIGNATURES)

Syntactic sugar for the incremental look case for which `steps=0` as well as the `offset`. This is
a case where from a start character we lazily accept the next sequence of characters stopping as
soon as a character fails to verify `λ(c)`.
See also [`isexactly`](@ref).
"""
incrlook(λ::Function) = (0, false, λ)


"""
TokenFinder

Convenience type to define tokens. The Tuple comes from the output of functions such as
[`isexactly`](@ref).
"""
const TokenFinder = Pair{Tuple{Int,Bool,Function},Symbol}


"""
$(SIGNATURES)

Go through a text left to right, one (valid) char at the time and keep track of sequences of chars
that match specific tokens. The list of tokens found is returned.

**Arguments**

* `str`:          the initial text
* `tokens_dict`:  dictionary of possible tokens (multiple characters long)
* `stokens_dict`: dictionaro of possible tokens (single character)
"""
function find_tokens(str::AbstractString,
                     tokens_dict::Dict{Char,Vector{TokenFinder}},
                     stokens_dict::Dict{Char,Symbol})::Vector{Token}
    # storage to keep track of the tokens found
    tokens = Vector{Token}()

    # head_idx will travel over the valid characters from first to final one
    # excluding it (the EOS character).
    head_idx, EOS_idx = 1, lastindex(str)

    while head_idx < EOS_idx
        # read the character and check if corresponds to start of token
        head = str[head_idx]

        # 1. is it one of the single-char token?
        if haskey(stokens_dict, head)
            push!(tokens, Token(stokens_dict[head], subs(str, head_idx)))

        # 2. is it one of the multi-char token?
        elseif haskey(tokens_dict, head)
            for ((steps, offset, λ), case) ∈ tokens_dict[head]
                #=
                ↪ steps = length of the lookahead, 0 if incremental
                ↪ offset = if we need to check one character 'too much'
                (e.g. this is the case if we want to check that something
                is followed by a space)
                ↪ λ = the checker function
                    * for a fixed lookahead, it returns true if the segment
                    (head_idx → head_idx + steps) matches a condition
                    * for an incremental lookahead, it returns true if chars
                    given meet a condition, chars after head_idx are fed while
                    the condition holds.

                Either way, we push to the 'memory' the exact span (without the
                potential offset) of the token and a symbol indicating what it
                is then we move the head at the end of the token (note that
                it's pushed by 1 again after the if-else-end to start again).
                =#
                if steps > 0 # exact match of a given fixed pattern
                    endchar_idx = nextind(str, head_idx, steps)
                    endchar_idx > EOS_idx && continue
                    stack = subs(str, head_idx, endchar_idx)
                    if λ(stack)
                        # offset==True --> looked at 1 extra char (lookahead)
                        head_idx = prevind(str, endchar_idx, offset)
                        push!(tokens, Token(case, chop(stack, tail=offset)))
                        # token identified, no need to check other cases.
                        break
                    end
                else # rule-based match, greedy catch until fail
                    stack, shift = head, 1
                    nextchar_idx = nextind(str, head_idx)
                    while λ(shift, str[nextchar_idx])
                        stack = subs(str, head_idx, nextchar_idx)
                        shift += 1
                        nextchar_idx = nextind(str, nextchar_idx)
                    end
                    endchar_idx = prevind(str, nextchar_idx)
                    if endchar_idx > head_idx
                        push!(tokens, Token(case, stack))
                        head_idx = endchar_idx
                    end
                end
            end
        end
        # dictionaries have been checked etc, moving on to the next valid char
        head_idx = nextind(str, head_idx)
    end
    return tokens
end
