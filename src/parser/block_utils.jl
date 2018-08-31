"""
bbalance(token)

Helper function to update the inbalance counter when looking for the closing
brace of a brace block. Adds 1 if the token corresponds to an opening brace,
removes 1 if it's a closing brace, adds nothing otherwise.
"""
function bbalance(τ::Token, open_close=[:LX_BRACE_OPEN, :LX_BRACE_CLOSE])
    return dot(τ.name .== open_close, [1, -1])
end


"""
    deactivate_xblocks(tokens, xbd)

Find blocks in the text that will be extracted and mark all tokens within these blocks as inactive in order to avoid them being processed further.
This allows, for example, to ignore any braces that appear in xblocks.
"""
function deactivate_xblocks(tokens::Vector{Token},
                            xbd::Dict{Symbol,Pair{Symbol,Symbol}})

    # mark all tokens as active to begin with
    active_tokens = ones(Bool, length(tokens))
    bracket_tokens = zeros(Bool, length(tokens))
    # go over tokens and process the ones announcing a code block
    for (i, τ) ∈ enumerate(tokens)
        active_tokens[i] || continue
        if haskey(xbd, τ.name)
            close_τ, _ = xbd[τ.name]
        else # ignore the token (does not announce an code block)
            continue
        end
        # seek forward to find the first closing token
        k = findfirst(cτ -> (cτ.name == close_τ), tokens[i+1:end])
        isnothing(k) && error("Found the opening token '$(τ.name)' but not the corresponding closing token. Verify.")
        # mark tokens within the block as inactive
        active_tokens[i:i+k] .= false
        bracket_tokens[[i, i+k]] .= true
    end
    return tokens[active_tokens .| bracket_tokens]
end
