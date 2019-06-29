"""
$(SIGNATURES)

Find active blocks between an opening token (`otoken`) and a closing token `ctoken`. These can be
nested (e.g. braces). Return the list of such blocks. If `deactivate` is `true`, all the tokens
within the block will be marked as inactive (for further, separate processing).
"""
function find_ocblocks(tokens::Vector{Token}, name::S, ocpair::Pair{S, S};
                         nestable=false, inmath=false) where S <: Symbol

    ntokens       = length(tokens)
    active_tokens = ones(Bool, length(tokens))
    ocblocks      = Vector{OCBlock}()

    # go over active tokens check if there's an opening token
    # if so look for the closing one and push
    for (i, τ) ∈ enumerate(tokens)
        # only consider active and opening tokens
        (active_tokens[i] & (τ.name == ocpair.first)) || continue
        # if nestable, need to keep track of the balance
        if nestable
            # inbalance ≥ 0, 0 if all opening tokens are closed
            inbalance = 1 # we've seen an opening token
            j = i # index for the closing token
            while !iszero(inbalance) & (j < ntokens)
                j += 1
                inbalance += ocbalance(tokens[j], ocpair)
            end
            if inbalance > 0
                throw(OCBlockError("I found at least one opening  token " *
                                   "'$(ocpair.first)' that is not closed properly."))
            end
        else
            # seek forward to find the first closing token
            j = findfirst(cτ -> (cτ.name == ocpair.second), tokens[i+1:end])
            # error if no closing token is found
            if isnothing(j)
                throw(OCBlockError("I found the opening token '$(τ.name)' but not " *
                                   "the corresponding closing token."))
            end
            j += i
        end
        push!(ocblocks, OCBlock(name, τ => tokens[j]))

        # remove processed tokens and tokens within blocks except if
        # it's a brace block in a math environment.
        span = ifelse((name == :LXB) & inmath, [i, j], i:j)
        active_tokens[span] .= false
    end
    return ocblocks, tokens[active_tokens]
end


"""
$(SIGNATURES)

Helper function to update the inbalance counter when looking for the closing token of a block with
nesting. Adds 1 if the token corresponds to an opening token, removes 1 if it's a closing token and
0 otherwise.
"""
function ocbalance(τ::Token, ocpair::Pair{Symbol,Symbol}=(:LX_BRACE_OPEN=>:LX_BRACE_CLOSE))::Int
    (τ.name == ocpair.first)  && return 1
    (τ.name == ocpair.second) && return -1
    return 0
end


"""
$(SIGNATURES)

Convenience function to find all ocblocks e.g. such as `MD_OCBLOCKS`. Returns a vector of vectors
of ocblocks.
"""
function find_all_ocblocks(tokens::Vector{Token},
                          ocblist::Vector{Pair{S,Tuple{Pair{S,S},Bool}}};
                          inmath=false) where S <: Symbol

    ocbs_all = Vector{OCBlock}()
    for (name, (ocpair, nestable)) ∈ ocblist
        ocbs, tokens = find_ocblocks(tokens, name, ocpair;
                                     nestable=nestable, inmath=inmath)
        append!(ocbs_all, ocbs)
    end

    # it may happen that a block is contained in a larger escape block.
    # For instance this can happen if there is a code block in an escape block (see e.g. #151).
    # To fix this, we browse the escape blocks in backwards order and check if there is any other
    # block within it.
    i = length(ocbs_all)
    active = ones(Bool, i)
    all_heads = from.(ocbs_all)
    while i > 1
        cur_ocb = ocbs_all[i]
        if active[i] && cur_ocb.name ∈ MD_OCB_ESC
            # find all blocks within the span of this block, deactivate all of them
            cur_head = all_heads[i]
            cur_tail = to(cur_ocb)
            mask = filter(j -> active[j] && cur_head < all_heads[j] < cur_tail, 1:i-1)
            active[mask] .= false
        end
        i -= 1
    end
    deleteat!(ocbs_all, map(!, active))
    return ocbs_all, tokens
end


"""
$(SIGNATURES)

Merge vectors of blocks by order of appearance of the blocks.
"""
function merge_blocks(lvb::Vector{<:AbstractBlock}...)
    blocks = vcat(lvb...)
    sort!(blocks, by=(β->from(β)))
    return blocks
end
