"""
    find_tokens(str, tokens_dict, stokens_dict)

Go through a text left to right, one (valid) char at the time and keep track of
sequences of chars that match specific tokens.
The list of tokens found is returned.
"""
function find_tokens(str::AbstractString, tokens_dict::Dict,
                     stokens_dict::Dict)
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

                NOTE: tokens are marked by single-byte character which
                means that we can do 'simple' string-index arithmetic.
                See https://docs.julialang.org/en/stable/manual/strings/
                =#
                if steps > 0 # exact match of a given fixed pattern
                    endchar_idx = head_idx + steps
                    endchar_idx > EOS_idx && continue
                    stack = subs(str, head_idx, endchar_idx)
                    if λ(stack)
                        # offset==True --> looked at 1 extra char (lookahead)
                        head_idx = endchar_idx - offset
                        push!(tokens, Token(case, chop(stack, tail=offset)))
                        # token identified, no need to check other cases.
                        break
                    end
                else # rule-based match, greedy catch until fail
                    stack, shift = head, 1
                    nextchar_idx = head_idx + shift
                    while λ(shift, str[nextchar_idx])
                        stack = subs(str, head_idx, nextchar_idx)
                        shift += 1
                        nextchar_idx += 1
                    end
                    endchar_idx = nextchar_idx - 1
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
