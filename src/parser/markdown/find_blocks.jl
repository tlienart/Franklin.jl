"""
    find_md_ocblocks(tokens, otoken, ctoken; deactivate, nestable)

Find active blocks between an opening token (`otoken`) and a closing token
`ctoken`. These can be nested (e.g. braces). Return the list of such blocks. If
`deactivate` is `true`, all the tokens within the block will be marked as
inactive (for further, separate processing).
"""
function find_md_ocblocks(tokens::Vector{Token}, name::S, ocpair::Pair{S, S};
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
    find_md_ocblocks(tokens)

Convenience function to find all ocblocks associated with `MD_OCBLOCKS`.
Returns a vector of vector of ocblocks.
"""
function find_md_ocblocks(tokens::Vector{Token}; inmath=false)
    ocbs_all = Vector{OCBlock}()
    for (name, (ocpair, nest)) ∈ MD_OCB_ALL
        ocbs, tokens = find_md_ocblocks(tokens, name, ocpair;
                                        nestable=nest, inmath=inmath)
        append!(ocbs_all, ocbs)
    end
    return ocbs_all, tokens
end
