"""
$(TYPEDEF)

This is the supertype defining a section of the string into consideration which
can be considered as a "block". For instance, `abc { ... } def` contains one
braces block corresponding to the substring `{ ... }`. All subtypes of
AbstractBlock must have a `ss` field corresponding to the substring associated
to the block. See also [`Token`](@ref), [`OCBlock`](@ref).
"""
abstract type AbstractBlock end

# convenience functions to locate the substring associated to a block
from(β::AbstractBlock) = from(β.ss)
to(β::AbstractBlock)   = to(β.ss)
str(β::AbstractBlock)  = str(β.ss)


"""
$(TYPEDEF)

A token `τ::Token` denotes a part of the source string indicating a region that
may need further processing. It is identified by a symbol `τ.name` (e.g.:
`:MATH_ALIGN_OPEN`). Tokens are typically used in this code to identify
delimiters of environments. For instance, `abc \$ ... \$ def` contains two
tokens `:MATH_A` associated with the `\$` sign. Together they delimit here an
inline math expression.
"""
struct Token <: AbstractBlock
    name::Symbol
    ss::SubString
    lno::Int  # for LRINDENT it's useful to store line number
end
Token(n, s) = Token(n, s, 0)

to(β::Token) = ifelse(β.name == :EOS, from(β), to(β.ss))

context(t::Token) = context(str(t), from(t))

"""
$(TYPEDEF)

A special block to wrap special characters like like a html entity and have it
left unaffected by the Markdown to HTML transformation so that it can be
inserted "as is" in the HTML.
"""
struct HTML_SPCH <: AbstractBlock
    ss::SubString
    r::String
end
HTML_SPCH(ss) = HTML_SPCH(ss, "")

"""
$(TYPEDEF)

Prototype for an open-close block (see [`OCBlock`](@ref)) with the symbol of
the opening token (e.g. `:MATH_A`) and a corresponding list of closing tokens
(e.g. `(:MATH_A,)`). See also their definitions in `parser/md_tokens.jl`.
"""
struct OCProto
    name::Symbol
    otok::Symbol
    ctok::NTuple{N, Symbol} where N
    nest::Bool
end
OCProto(a...; nestable=false) = OCProto(a..., nestable)

"""
$(TYPEDEF)

Open-Close block, blocks that are defined by an opening `Token` and a closing
`Token`, they may be nested. For instance braces block are formed of an opening
`{` and a closing `}` and could be nested.
"""
struct OCBlock <: AbstractBlock
    name::Symbol
    ocpair::Pair{Token,Token}
    ss::SubString
end


"""
$(SIGNATURES)

Shorthand constructor to instantiate an `OCBlock` inferring the associated
substring from the `ocpair` (since it's the substring in between the tokens).
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

Convenience function to get the name of a lx-env delimiter (ignores spaces).
"""
function envname(τ::Token)
    m = match(LX_ENVNAME_PAT, τ.ss)
    isnothing(m) || return m.captures[1]
    # should not happen
    error("`envname` called on token of type $(τ.name) failed to return.")
end
envname(b::OCBlock) = envname(otok(b))


"""
$(SIGNATURES)

Convenience function to return the content of an open-close block (`OCBlock`),
for instance the content of a `{...}` block would be `...`.
"""
function content(ocb::OCBlock)::SubString
    s = str(ocb.ss) # this does not allocate
    cfrom = nextind(s, to(otok(ocb)))
    c = ctok(ocb)
    if c.name == :EOS
        cto = from(c)
    else
        cto = prevind(s, from(c))
    end
    return subs(s, cfrom, cto)
end

"""
$(SIGNATURES)

Convenience function to strip the content of a block.
"""
stent = strip ∘ content

#=
FUNCTIONS / CONSTANTS THAT HELP DEFINE TOKENS
=#

"""
EOS

Convenience symbol to mark the end of the string to parse (helps with corner
cases where a token ends a document without being followed by a space).
"""
const EOS = '\0'

"""
SPACE_CHARS

Convenience list of characters that would correspond to a `\\s` regex. see also
https://github.com/JuliaLang/julia/blob/master/base/strings/unicode.jl.
To this are added things that would definitely switch token:
* EOS (end of string)
* '}' (if in command)
"""
const SPACE_CHAR = (' ', '\n', '\t', '\v', '\f', '\r', '\u85', '\ua0',
                    EOS, '}')

"""
SPACER

Convenience list of characters corresponding to digits.
"""
const NUM_CHAR   = ('1', '2', '3', '4', '5', '6', '7', '8', '9', '0')

"""
$(SIGNATURES)

Forward lookup checking if a sequence of characters matches `refstring` and is
followed (or not followed if `isfollowed==false`) by a character out of a list
of characters (`follow`). It returns

1. a number of steps indicating the number of characters to check,
2. whether there is an offset or not (if it is required to check a following
character or not),
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
                   isfollowed=true)::Tuple{Int,Bool,Function,Bool}
    # number of code units from the start character
    steps = prevind(refstring, lastindex(refstring))
    # no offset (don't check next character)
    isempty(follow) && return (steps, false, (s,_) -> (s == refstring), false)
    # will include next char for verification (--> offset of 1)
    steps  = lastindex(refstring)
    nochop = !isfollowed || EOS ∈ follow
    # verification function; we want either (false false or true true))
    # NOTE, chop because we will take the next char with it

    λ(s, at_eos) = at_eos ?
                    # if at_eos  then we don't get an extra char, compare as is
                    # if isfollowed, then check EOS in follow
                    s == refstring && !isfollowed || EOS ∈ follow :
                    # if not, get extra char, compare  with
                    chop(s) == refstring && !xor(isfollowed, s[end] ∈ follow)

    return (steps, true, λ, nochop)
end

"""
$(SIGNATURES)

Check whether `c` is a letter or is in a vector of character `ac`.
"""
α(c::Char, ac::NTuple{K,Char}=()) where K = isletter(c) || (c ∈ ac)

"""
$(SIGNATURES)

Check whether `c` is alpha numeric or in vector of character `ac`
"""
αη(c::Char, ac::NTuple{K,Char}=()) where K = α(c, tuple(ac..., NUM_CHAR...))

"""
$(SIGNATURES)

Syntactic sugar for the incremental look case for which `steps=0` as well as
the `offset`. This is a case where from a start character we lazily accept the
next sequence of characters stopping as soon as a character fails to verify
`λ(c)`. See also [`isexactly`](@ref).
"""
incrlook(λ::Function, validator=nothing) = (0, false, λ, validator)

"""
$(SIGNATURES)

In combination with `incrlook`, checks to see if we have something that looks
like a @@div describing the opening of a div block. Triggering char is a first
`@`.
"""
is_div_open(i::Int, c::Char) = (i == 1 && return c == '@'; return α(c, ('-','_', ',', NUM_CHAR...)))

"""
$(SIGNATURES)

In combination with `incrlook`, checks to see if we have something that looks
like a triple backtick followed by a valid combination of letter defining a
language. Triggering char is a first backtick.
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

In combination with `incrlook`, checks to see if we have something that looks
like a html entity. Note that there can be fake matches, so this will need to
be validated later on; if validated it will be treated as HTML; otherwise it
will be shown as markdown. Triggerin char is a `&`.
"""
is_html_entity(i::Int, c::Char) = αη(c, ('#',';'))

"""
$(SIGNATURES)

Check if it looks like an emoji indicator `:...` note that it does
not take the final `:` this is checked and added in `validate_emoji!`.
"""
is_emoji(i::Int, c::Char) = αη(c, ('+','_','-'))

"""
$(SIGNATURES)

Check if it looks like `\\[\\^[\\p{L}0-9]+\\]:`.
"""
function is_footnote(i::Int, c::Char)
    i == 1 && return c == '^'
    i == 2 && return αη(c)
    i > 2  && return αη(c, (']', ':'))
end

"""
$SIGNATURES

Check if it looks like `---+`.
"""
is_hr1(::Int, c::Char) = c == '-'

"""
$SIGNATURES

Check if it looks like `___+`.
"""
is_hr2(::Int, c::Char) = c == '_'

"""
$SIGNATURES

Check if it looks like `***+`.
"""
is_hr3(::Int, c::Char) = c == '*'


"""
TokenFinder

Convenience type to define tokens. The Tuple comes from the output of functions
such as [`isexactly`](@ref).
"""
const TokenFinder =
        Pair{
            Tuple{
                Int,
                Bool,
                Function,
                Union{Bool,Nothing,Function}},
            Symbol}


"""
$(SIGNATURES)

Go through a text left to right, one (valid) char at the time and keep track of
sequences of chars that match specific tokens. The list of tokens found is
returned.

**Arguments**

* `str`:   the initial text
* `dictn`: dictionary of possible tokens (multiple characters long)
* `dict1`: dictionaro of possible tokens (single character)
"""
function find_tokens(str::AS,
                     dictn::AbstractDict{Char,Vector{TokenFinder}},
                     dict1::AbstractDict{Char,Symbol})::Vector{Token}
    isempty(str) && return Token[]
    # storage to keep track of the tokens found
    tokens    = Vector{Token}()
    head_idx  = 1                # valid string index
    end_idx   = lastindex(str)   # outer bound
    while head_idx <= end_idx
        head_char = str[head_idx]
        # 1. is it one of the single-char token?
        if haskey(dict1, head_char)
            tok = Token(dict1[head_char], subs(str, head_idx))
            push!(tokens, tok)

        # 2. is it one of the multi-char token?
    elseif haskey(dictn, head_char)
            for ((steps, offset, λ, ν), case) ∈ dictn[head_char]
                #=
                ↪ steps = length of the lookahead, 0 if incremental (greedy)
                ↪ offset = if we need to check one character 'too much'
                (e.g. this is the case if we want to check that something
                is followed by a space)
                ↪ λ = the checker function
                    * for a fixed lookahead, it returns true if the segment
                    (head_idx → head_idx + steps) matches a condition
                    * for an incremental lookahead, it returns true if chars
                    given meet a condition, chars after head_idx are fed while
                    the condition holds.
                ↪ ν = the (optional) validator function in the case of a greedy
                    lookahead to check whether the sequence is valid

                Either way, we push to the 'memory' the exact span (without the
                potential offset) of the token and a symbol indicating what it
                is then we move the head at the end of the token (note that
                it's pushed by 1 again after the if-else-end to start again).
                =#
                if steps > 0 # exact match of a given fixed pattern
                    tail_idx = nextind(str, head_idx, steps)
                    # is there space for the fixed pattern?
                    at_eos = false
                    if ν && tail_idx == nextind(str, end_idx)
                        tail_idx = end_idx
                        at_eos = true
                    end
                    tail_idx > end_idx && continue
                    # consider the substring and verify whether it matches
                    cand_seq = subs(str, head_idx, tail_idx)
                    if λ(cand_seq, at_eos)
                        # if offset==True --> looked at 1 extra char (lookahead)
                        back_one = offset & !at_eos
                        head_idx = prevind(str, tail_idx, back_one)
                        tok = Token(case, chop(cand_seq, tail=back_one))
                        push!(tokens, tok)
                        # token identified, no need to check other cases.
                        break
                    end
                else # rule-based match: greedy catch until fail
                    nchars     = 1
                    tail_idx   = head_idx
                    probe_idx  = nextind(str, head_idx)
                    probe_idx > end_idx && continue
                    probe_char = str[probe_idx]
                    while λ(nchars, probe_char)
                        tail_idx   = probe_idx
                        probe_idx  = nextind(str, probe_idx)
                        probe_idx > end_idx && break
                        probe_char = str[probe_idx]
                        nchars   += 1
                    end
                    if tail_idx > head_idx
                        cand_seq = subs(str, head_idx, tail_idx)
                        # check if the validator is happy otherwise skip
                        isnothing(ν) || ν(cand_seq) || continue
                        # if it's happy push the token & move after the match
                        tok = Token(case, cand_seq)
                        push!(tokens, tok)
                        head_idx = tail_idx
                    end
                end
            end
        end
        head_idx  = nextind(str, head_idx)
    end
    # finally push the end token
    eos = Token(:EOS, subs(str, end_idx))
    push!(tokens, eos)
    return tokens
end
