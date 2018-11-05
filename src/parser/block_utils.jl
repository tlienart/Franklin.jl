"""
    find_ocblocks(tokens, otoken, ctoken; deactivate, nestable)

Find active blocks between an opening token (`otoken`) and a closing token
`ctoken`. These can be nested (e.g. braces). Return the list of such blocks. If
`deactivate` is `true`, all the tokens within the block will be marked as
inactive (for further, separate processing).
"""
function find_ocblocks(tokens::Vector{Token}, name::S, ocpair::Pair{S, S};
                         nestable=false, inmath=false) where S <: Symbol

    # number of tokens & active tokens
    ntokens = length(tokens)
    active_tokens = ones(Bool, length(tokens))
    # storage for the blocks
    ocblocks = Vector{OCBlock}()

    # go over active tokens check if there's an opening token, if so look for
    # the closing one.
    for (i, τ) ∈ enumerate(tokens)
        # only consider active
        (active_tokens[i] & (τ.name == ocpair.first)) || continue
        # if nestable, need to keep track of the balance
        if nestable
            # inbalance ≥ 0, 0 if all opening tokens are closed
            inbalance = 1 # we've seen an opening token
            # index for the closing token
            j = i
            while !iszero(inbalance) & (j < ntokens)
                j += 1
                inbalance += ocbalance(tokens[j], ocpair)
            end
            (inbalance > 0) && error("I found at least one opening token '$(ocpair.first)' that is not closed properly. Verify.")
        else
            # seek forward to find the first closing token
            j = findfirst(cτ -> (cτ.name == ocpair.second), tokens[i+1:end])
            # error if no closing token is found
            isnothing(j) && error("Found the opening token '$(τ.name)' but not the corresponding closing token. Verify.")
            j += i
        end
        push!(ocblocks, OCBlock(name, τ => tokens[j]))

        # remove processed tokens and tokens within blocks except if
        # it's a brace block in a math environment.
        if name == :LXB && inmath
            active_tokens[[i, j]] .= false
        else
            active_tokens[i:j] .= false
        end
    end

    return ocblocks, tokens[active_tokens]
end


"""
    find_all_ocblocks(tokens, dict)

Convenience function to find all ocblocks e.g. such as `MD_OCBLOCKS`.
Returns a vector of vectors of ocblocks.
"""
function find_all_ocblocks(tokens::Vector{Token},
                          ocblist::Vector{Pair{S,Tuple{Pair{S, S},Bool}}};
                          inmath=false) where S <: Symbol

    ocbs_all = Vector{OCBlock}()
    for (name, (ocpair, nest)) ∈ MD_OCB_ALL
        ocbs, tokens = find_ocblocks(tokens, name, ocpair;
                                     nestable=nest, inmath=inmath)
        append!(ocbs_all, ocbs)
    end
    return ocbs_all, tokens
end


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


# XXX obsolete, would disappear
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
    # go over tokens and process the ones announcing a block to deactivate
    for (i, τ) ∈ enumerate(tokens)
        active_tokens[i] || continue
        if haskey(bd, τ.name)
            close_τ, _ = bd[τ.name]
        else # ignore the token (does not announce a block to deactivate)
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
    from_ifsmaller(v, idx, len)

Convenience function to check if `idx` is smaller than the length of `v`, a
vector of `<:AbstractBlock` or of `LxDef`, if it is, then return the starting
point of that block, otherwise return `BIG_INT`.
"""
from_ifsmaller(v::Vector, idx::Int, len::Int) =
    (idx > len) ? BIG_INT : from(v[idx])


"""
    merge_blocks(lvb)

Merge vectors of blocks by order of appearance of the blocks.
"""
function merge_blocks(lvb::Vector{<:AbstractBlock}...)
    blocks = vcat(lvb...)
    sort!(blocks, by=(β->from(β)))
    return blocks
end


"""
    deactivate_divs

Since divs are recursively processed, once they've been found, everything
inside them needs to be deactivated and left for further re-processing to
avoid double inclusion.
"""
function deactivate_divs(blocks::Vector{OCBlock})
    active_blocks = ones(Bool, length(blocks))
    for (i, β) ∈ enumerate(blocks)
        fromβ, toβ = from(β), to(β)
        active_blocks[i] || continue
        if β.name == :DIV
            innerblocks = findall(b -> fromβ < from(b) < toβ, blocks)
            active_blocks[innerblocks] .= false
        end
    end
    return blocks[active_blocks]
end
