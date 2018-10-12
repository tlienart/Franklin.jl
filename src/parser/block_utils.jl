"""
ocbalance(token)

Helper function to update the inbalance counter when looking for the closing
token of a block with nesting. Adds 1 if the token corresponds to an opening
token, removes 1 if it's a closing token. 0 otherwise.
"""
function ocbalance(τ::Token, ocpair=(:LX_BRACE_OPEN => :LX_BRACE_CLOSE))
    (τ.name == ocpair.first) && return 1
    (τ.name == ocpair.second) && return -1
    return 0
end


"""
    deactivate_blocks(tokens, bd)

Find blocks in the text to escape before further processing. Mark all tokens
within their span as inactive.
"""
function deactivate_blocks(tokens::Vector{Token},
                           bd::Dict{Symbol,Pair{Symbol,Symbol}})

    # mark all tokens as active to begin with
    active_tokens = ones(Bool, length(tokens))
    # keep track of the boundary tokens
    boundary_tokens = zeros(Bool, length(tokens))
    # go over tokens and process the ones announcing a code block
    for (i, τ) ∈ enumerate(tokens)
        active_tokens[i] || continue
        if haskey(bd, τ.name)
            close_τ, _ = bd[τ.name]
        else # ignore the token (does not announce an code block)
            continue
        end
        # seek forward to find the first closing token
        k = findfirst(cτ -> (cτ.name == close_τ), tokens[i+1:end])
        isnothing(k) && error("Found the opening token '$(τ.name)' but not the corresponding closing token. Verify.")
        # mark tokens within the block as inactive
        active_tokens[i:i+k] .= false
        boundary_tokens[[i, i+k]] .= true
    end
    return tokens[active_tokens .| boundary_tokens]
end


"""
    merge_blocks(lvb)

Merge vectors of blocks by order of appearance of the blocks.
"""
function merge_blocks(lvb::Vector{<:AbstractBlock}...)
    vbs_len = [length(vb) for vb ∈ lvb]
    blocks = Vector{AbstractBlock}(undef, sum(vbs_len)) # to contain all blocks
    vbs_index = ones(Int, length(lvb))
    vbs_from = from_ifsmaller.(lvb, vbs_index, vbs_len)

    for i ∈ eachindex(blocks)
        k = argmin(vbs_from)
        blocks[i] = lvb[k][vbs_index[k]]
        vbs_index[k] += 1
        vbs_from[k] = from_ifsmaller(lvb[k], vbs_index[k], vbs_len[k])
    end
    return blocks
end


"""
    from_ifsmaller(vb, vb_idx, vb_len)

Convenience function to check if `vb_idx` is smaller than the length of `vb`, a
vector of `<:AbstractBlock`, if it is, then return the starting point of that
block, otherwise return `BIG_INT`.
"""
from_ifsmaller(vb::Vector{<:AbstractBlock}, vb_idx::Int, vb_len::Int) =
    (vb_idx > vb_len) ? BIG_INT : from(vb[vb_idx])
