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
math expression.
"""
struct Token <: AbstractBlock
    name::Symbol
    ss::SubString
end

to(β::Token) = ifelse(β.name == :EOS, from(β), to(β.ss))

"""
$(TYPEDEF)

A special block to wrap special characters like like a html entity and have it left unaffected
by the Markdown to HTML transformation so that it can be  inserted "as is" in the HTML.
"""
struct HTML_SPCH <: AbstractBlock
    ss::SubString
    r::String
end
HTML_SPCH(ss) = HTML_SPCH(ss, "")


"""
$(TYPEDEF)

Prototype for an open-close block (see [`OCBlock`](@ref)) with the symbol of the opening token
(e.g. `:MATH_A`) and a corresponding list of closing tokens (e.g. `(:MATH_A,)`).
See also their definitions in `parser/md_tokens.jl`.
"""
struct OCProto
    name::Symbol
    otok::Symbol
    ctok::NTuple{N, Symbol} where N
    nest::Bool
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
OCBlock(η::Symbol, ω::Pair{Token,Token}, nestable::Bool=false) =
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
const SPACER = (' ', '\n', '\t', '\v', '\f', '\r', '\u85', '\ua0', EOS)


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
function isexactly(refstring::AS, follow::NTuple{K,Char} where K = (),
                   isfollowed=true)::Tuple{Int,Bool,Function,Nothing}
    # number of steps from the start character
    steps = prevind(refstring, lastindex(refstring))
    # no offset (don't check next character)
    isempty(follow) && return (steps, false, s -> (s == refstring), nothing)
    # include next char for verification (--> offset of 1)
    steps = nextind(refstring, steps)
    # verification function; we want either (false false or true true))
    λ(s) = (chop(s) == refstring) && !xor(isfollowed, s[end] ∈ follow)
    return (steps, true, λ, nothing)
end


"""
$(SIGNATURES)

Check whether `c` is a letter or is in a vector of character `ac`.
"""
α(c::Char, ac::NTuple{K,Char}=()) where {K} = isletter(c) || (c ∈ ac)

"""
$(SIGNATURES)

Check whether `c` is alpha numeric or in vector of character `ac`
"""
αη(c::Char, ac::NTuple{K,Char}=()) where {K} = α(c, tuple(ac..., ("$i"[1] for i in 0:9)...))

"""
$(SIGNATURES)

Syntactic sugar for the incremental look case for which `steps=0` as well as the `offset`. This is
a case where from a start character we lazily accept the next sequence of characters stopping as
soon as a character fails to verify `λ(c)`.
See also [`isexactly`](@ref).
"""
incrlook(λ::Function, validator=nothing) = (0, false, λ, validator)

"""
$(SIGNATURES)

In combination with `incrlook`, checks to see if we have something that looks like a @@div
describing the opening of a div block. Triggering char is a first `@`.
"""
is_div_open(i::Int, c::Char) = (i == 1 && return c == '@'; return α(c, ('-',)))

"""
$(SIGNATURES)

In combination with `incrlook`, checks to see if we have something that looks like a triple
backtick followed by a valid combination of letter defining a language. Triggering char is a
first backtick.
"""
is_language() = incrlook(_is_language, _validate_language)

function _is_language(i::Int, c::Char)
    i < 3  && return c == '`'  # ` followed by `` forms the opening ```
    i == 3 && return α(c)      # must be a letter
    return α(c, ('-',))        # can be a letter or a hyphen, for instance ```objective-c
end

_validate_language(stack::AS) = !isnothing(match(r"^```[a-zA-Z]", stack))


"""
$(SIGNATURES)

See [`is_language`](@ref) but with 5 ticks.
"""
is_language2() = incrlook(_is_language2, _validate_language2)

function _is_language2(i::Int, c::Char)
    i < 5  && return c == '`'
    i == 5 && return α(c)
    return α(c, ('-',))
end

_validate_language2(stack::AS) = !isnothing(match(r"^`````[a-zA-Z]", stack))


"""
$(SIGNATURES)

In combination with `incrlook`, checks to see if we have something that looks like a html entity.
Note that there can be fake matches, so this will need to be validated later on; if validated
it will be treated as HTML; otherwise it will be shown as markdown. Triggerin char is a `&`.
"""
is_html_entity(i::Int, c::Char) = αη(c, ('#',';'))

"""
$(SIGNATURES)

Check if it looks like `\\[\\^[a-zA-Z0-9]+\\]:`.
"""
function is_footnote(i::Int, c::Char)
    i == 1 && return c == '^'
    i == 2 && return αη(c)
    i > 2  && return αη(c, (']', ':'))
end

"""
TokenFinder

Convenience type to define tokens. The Tuple comes from the output of functions such as
[`isexactly`](@ref).
"""
const TokenFinder = Pair{Tuple{Int,Bool,Function,Union{Nothing,Function}},Symbol}


"""
$(SIGNATURES)

Go through a text left to right, one (valid) char at the time and keep track of sequences of chars
that match specific tokens. The list of tokens found is returned.

**Arguments**

* `str`:          the initial text
* `tokens_dict`:  dictionary of possible tokens (multiple characters long)
* `stokens_dict`: dictionaro of possible tokens (single character)
"""
function find_tokens(str::AS,
                     tokens_dict::AbstractDict{Char,Vector{TokenFinder}},
                     stokens_dict::AbstractDict{Char,Symbol})::Vector{Token}
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
            for ((steps, offset, λ, ν), case) ∈ tokens_dict[head]
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
                        # if the validator is unhappy, don't move the head and
                        # consider other rules
                        isnothing(ν) || ν(stack) || continue
                        # otherwise move ahead after the match
                        push!(tokens, Token(case, stack))
                        head_idx = endchar_idx
                    end
                end
            end
        end
        # dictionaries have been checked etc, moving on to the next valid char
        head_idx = nextind(str, head_idx)
    end
    push!(tokens, Token(:EOS, subs(str, EOS_idx, EOS_idx)))
    return tokens
end
