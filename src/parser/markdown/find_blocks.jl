"""
    find_md_bblocks(tokens)

Find active open brace characters `{` and their matching closing braces. Return
the list of such `bblocks` (braces blocks).
"""
function find_md_bblocks(tokens::Vector{Token})
    # number of tokens & active tokens
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
        (inbalance > 0) && error("I found at least one open curly brace '{' that is not closed properly. Verify.")
        push!(bblocks, braces(subs(str(τ), from(τ), to(tokens[j]))))
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
        ismath = false # is it a math block? default = false
        if haskey(MD_EXTRACT, τ.name)
            close_τ, bname = MD_EXTRACT[τ.name]
        elseif haskey(MD_MATHS, τ.name)
            close_τ, bname = MD_MATHS[τ.name]
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
        push!(xblocks, Block(bname, subs(str(τ), from(τ), to(tokens[k]))))
        # mark tokens within the block as inactive (extracted blocks are not
        # further processed unless they're math blocks where potential
        # user-defined latex commands will be further processed)
        active_tokens[i:k] .= false
    end
    return xblocks, tokens[active_tokens]
end

"""
    merge_xblocks_lxcoms(xb, lxc)

Form a list of `AbstractBlock` corresponding to the list of blocks to insert
after `md2html` is called. The blocks are extracted separately and this
function merges them in order of appearance.
"""
function merge_xblocks_lxcoms(xb::Vector{Block}, lxc::Vector{LxCom})

    isempty(xb) && return lxc
    isempty(lxc) && return xb

    lenxb, lenlxc = length(xb), length(lxc)
    xblocks = Vector{AbstractBlock}(undef, lenxb + lenlxc)

    xb_i, lxc_i = 1, 1
    xb_from, lxc_from = from(xb[xb_i]), from(lxc[lxc_i])

    for i ∈ eachindex(xblocks)
        if xb_from < lxc_from
            xblocks[i] = xb[xb_i]
            xb_i += 1
            xb_from = (xb_i > lenxb) ? BIG_INT : from(xb[xb_i])
        else
            xblocks[i] = lxc[lxc_i]
            lxc_i += 1
            lxc_from = (lxc_i > lenlxc) ? BIG_INT : from(lxc[lxc_i])
        end
    end
    return xblocks
end
