"""
    find_md_ocblocks(tokens, otoken, ctoken; deactivate, nestable)

Find active blocks between an opening token (`otoken`) and a closing token
`ctoken`. These can be nested (e.g. braces). Return the list of such blocks. If
`deactivate` is `true`, all the tokens within the block will be marked as
inactive (for further, separate processing).
"""
function find_md_ocblocks(tokens::Vector{Token}, name::S, ocpair::Pair{S, S};
                          deactivate=true, nestable=true) where S <: Symbol
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
            while !iszero(inbalance) & (j <= ntokens)
                j += 1
                inbalance += ocbalance(tokens[j], ocpair)
            end
            (inbalance > 0) && error("I found at least one opening token '$(ocpair.first)' that is not closed properly. Verify.")
        else
            # seek forward to find the first closing token
            j = findfirst(cτ -> (cτ.name == ocpair.second), tokens[i+1:end])
            # error if no closing token is found
            isnothing(j) && error("Found the opening token '$(τ.name)' but not the corresponding closing token. Verify.")
        end
        push!(ocblocks, OCBlock(name, τ => tokens[j]))
        # remove processed tokens and inner tokens if deactivate
        if deactivate
            active_tokens[i:j] .= false
        else
            active_tokens[[i, j]] .= false
        end
    end
    return ocblocks, tokens[active_tokens]
end


"""
    find_md_xblocks(tokens)

Find blocks of text that will be extracted (see `MD_EXTRACT`, `MD_MATHS`).
Blocks are searched for in order, tokens that are contained in a extracted
block are deactivated (unless it's a maths block in which case latex tokens are
preserved). The function returns the list of blocks as well as a shrunken list
of active tokens. These blocks cannot be nested.
"""
function find_md_xblocks(tokens::Vector{Token})
    # storage for blocks to extract (we don't know how many will be retrieved)
    xblocks = Vector{Block}()
    # mark all tokens as active to begin with
    active_tokens = ones(Bool, length(tokens))
    # go over tokens and process the ones announcing a block to extract
    for (i, τ) ∈ enumerate(tokens)
        active_tokens[i] || continue
        if haskey(MD_EXTRACT, τ.name)
            close_τ, bname = MD_EXTRACT[τ.name]
        elseif haskey(MD_MATHS, τ.name)
            close_τ, bname = MD_MATHS[τ.name]
        else
            # ignore the token (does not announce an extract block)
            continue
        end
        # seek forward to find the first closing token
        k = findfirst(cτ->(cτ.name == close_τ), tokens[i+1:end])
        isnothing(k) && error("Found the opening token '$(τ.name)' but not the corresponding closing token. Verify.")
        # store the block
        k += i
        push!(xblocks, Block(bname, subs(str(τ), from(τ), to(tokens[k]))))
        # mark tokens within the block as inactive (extracted blocks are not
        # further processed unless they're math blocks where potential
        # user-defined latex commands will be further processed)
        active_tokens[i:k] .= false
    end
    return xblocks, tokens[active_tokens]
end
