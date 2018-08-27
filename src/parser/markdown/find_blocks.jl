"""
    find_md_bblocks(tokens)

Find active open brace characters `{` and their matching closing braces. Return
the list of such `bblocks` (braces blocks).
"""
function find_md_bblocks(tokens::Vector{Token})
    ntokens = length(tokens)
    active_tokens = ones(Bool, length(tokens))
    # storage for the blocks `{...}`
    bblocks = Vector{Block}()
    # look for tokens indicating an opening brace
    for (i, τ) ∈ enumerate(tokens)
        # only consider active open braces
        (active_tokens[i] & (τ.name == :LX_BRACE_OPEN)) || continue
        # inbalance keeps track of whether we've closed all braces (0) or not
        inbalance = 1
        # index for the closing brace: seek forward in list of active tokens
        j = i
        while !iszero(inbalance) & (j <= ntokens)
            j += 1
            inbalance += bbalance(tokens[j])
        end
        (inbalance > 0) && error("I found at least one open curly brace that is not closed properly. Verify.")
        push!(bblocks, braces(τ.from, tokens[j].to))
        # remove processed tokens
        active_tokens[[i, j]] .= false
    end
    return bblocks, tokens[active_tokens]
end


"""
    find_md_xblocks(tokens)

Find blocks of text that will be extracted (see `MD_EXTRACT`, `MD_MATHS`).
Blocks are searched for in order, tokens that are contained in a extracted
block are deactivated (unless it's a maths block in which case latex tokens are
preserved). The function returns the list of blocks as well as a shrunken list
of active tokens.
"""
function find_md_xblocks(tokens::Vector{Token})
    # storage for blocks to extract (we don't know how many will be retrieved)
    xblocks = Vector{Block}()
    # mark all tokens as active to begin with
    active_tokens = ones(Bool, length(tokens))
    # go over tokens and process the ones announcing a block to extract
    for (i, τ) ∈ enumerate(tokens)
        active_tokens[i] || continue
        ismaths = false # is it a math block? default = false
        if haskey(MD_EXTRACT, τ.name)
            close_τ, bname = MD_EXTRACT[τ.name]
        elseif haskey(MD_MATHS, τ.name)
            #= NOTE: there is a corner case where this block is actually
            encapsulated in the definition of a command (via \newcommand)
            this is resolved at subsequent step "find_md_lxdefs"
            =#
            close_τ, bname = MD_MATHS[τ.name]
            ismaths = true
        elseif τ.name ∈ [:DIV_OPEN, :DIV_CLOSE]
            push!(xblocks, τ)
            continue
        else
            # ignore the token (does not announce an extract block)
            continue
        end
        # seek forward to find the first closing token
        k = findfirst(cτ->(cτ.name == close_τ), tokens[i+1:end])
        isnothing(k) && error("Found the opening token '$(τ.name)' but not the corresponding closing token. Verify.")
        # store the block
        k += i
        push!(xblocks, Block(bname, τ.from, tokens[k].to))
        # mark tokens within the block as inactive (extracted blocks are not
        # further processed unless they're math blocks where potential
        # user-defined latex commands will be further processed)
        active_tokens[i:k] .= ifelse(ismaths, map(islatex, tokens[i:k]), false)
    end
    return xblocks, tokens[active_tokens]
end

#=
TODO TODO
* add DOC !
=#
function merge_xblocks_lxcoms(xb::Vector{Block}, lxc::Vector{LxCom})

    isempty(xb) && return lxc
    isempty(lxc) && return xb

    lenxb, lenlxc = length(xb), length(lxc)
    xblocks = Vector{AbstractBlock}(undef, lenxb + lenlxc)

    xb_i, lxc_i = 1, 1
    xb_from, lxc_from = xb[xb_i].from, lxc[lxc_i].from

    for i ∈ eachindex(xblocks)
        if xb_from < lxc_from
            xblocks[i] = xb[xb_i]
            xb_i += 1
            xb_from = (xb_i > lenxb) ? BIG_INT : xb[xb_i].from
        else
            xblocks[i] = lxc[lxc_i]
            lxc_i += 1
            lxc_from = (lxc_i > lenlxc) ? BIG_INT : lxc[lxc_i].from
        end
    end
    return xblocks
end


# """
#     get_md_allblocks(xblocks, lxdefs, strlen)
#
# Given a list of blocks, find the interstitial blocks, tag them as `:REMAIN`
# blocks and return a full list of blocks spanning the string.
# """
# function get_md_allblocks(xblocks::Vector{AbstractBlock},
#                           lxdefs::Vector{LxDef}, strlen::Int)
#
#     allblocks = Vector{Block}()
#     lenxb = length(xblocks)
#     lenlx = length(lxdefs)
#
#     next_xblock = iszero(lenxb) ? BIG_INT : xblocks[1].from
#     next_lxdef = iszero(lenlx) ? BIG_INT : lxdefs[1].from
#
#     # check which block is next
#     xb_or_lx = (next_xblock < next_lxdef)
#     next_idx = min(next_xblock, next_lxdef)
#
#     head, xb_idx, lx_idx = 1, 1, 1
#     while (next_idx < BIG_INT) & (head < strlen)
#         # check if there's anything before head and next block and push
#         (head < next_idx) && push!(allblocks, remain(head, next_idx-1))
#
#         if xb_or_lx # next block is xblock
#             β = xblocks[xb_idx]
#             push!(allblocks, β)
#             head = β.to + 1
#             xb_idx += 1
#             next_xblock = (xb_idx > lenxb) ? BIG_INT : xblocks[xb_idx].from
#         else # next block is newcommand, no push
#             head = lxdefs[lx_idx].to + 1
#             lx_idx += 1
#             next_lxdef = (lx_idx > lenlx) ? BIG_INT : lxdefs[lx_idx].from
#         end
#
#         # check which block is next
#         xb_or_lx = (next_xblock < next_lxdef)
#         next_idx = min(next_xblock, next_lxdef)
#     end
#     # add final one if exists
#     (head < strlen) && push!(allblocks, remain(head, strlen))
#     return allblocks
# end
