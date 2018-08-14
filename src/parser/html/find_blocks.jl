"""
    find_html_hblocks(tokens)

Find blocks surrounded by `{{...}}`.
"""
function find_html_hblocks(tokens::Vector{Token})
    #
    ntokens = length(tokens)
    active_tokens = ones(Bool, length(tokens))
    # storage for the blocks `{...}`
    hblocks = Vector{Block}()
    # look for tokens indicating an opening brace
    for (i, τ) ∈ enumerate(tokens)
         # only consider active open braces
         (active_tokens[i] & (τ.name == :H_BLOCK_OPEN)) || continue
         # inbalance keeps track of whether we've closed all braces (0) or not
         inbalance = 1
         # index for the closing brace: seek forward in list of active tokens
         j = i
         while !iszero(inbalance) & (j <= ntokens)
             j += 1
             inbalance += bbalance(tokens[j], [:H_BLOCK_OPEN, :H_BLOCK_CLOSE])
         end
         (inbalance > 0) && error("I found at least one open curly brace that is not closed properly. Verify.")
         push!(hblocks, hblock(τ.from, tokens[j].to))
         # remove processed tokens and mark inner tokens as inactive!
         # these will be re-processed in recursion
         active_tokens[i:j] = false
    end
    return hblocks, tokens[active_tokens]
end


function qualify_html_hblocks(blocks::Vector{Block}, s::String)
    qb = Vector{HBlock}(length(blocks))
    for (i, β) ∈ enumerate(blocks)
        ts = s[β.from:β.to]
        # if block {{ if v }}
        m = match(HBLOCK_IF, ts)
        (m == nothing) ||
            (qb[i] = HIf(m.captures[1], β.from, β.to); continue)
        # else block {{ else }}
        m = match(HBLOCK_ELSE, ts)
        (m == nothing) ||
            (qb[i] = HElse(β.from, β.to); continue)
        # else if block {{ else if v }}
        m = match(HBLOCK_ELSE_IF, ts)
        (m == nothing) ||
            (qb[i] = HElseIf(m.captures[1], β.from, β.to); continue)
        # end block {{ end }}
        m = match(HBLOCK_END, ts)
        (m == nothing) ||
            (qb[i] = HEnd(β.from, β.to); continue)
        # function block {{ fname v1 v2 ... }}
        m = match(HBLOCK_FUN, ts)
        (m == nothing) ||
            (qb[i] = HFun(m.captures[1], split(m.captures[2]), β.from, β.to);
            continue)
        error("I found a HBlock that did not match anything, verify '$ts'")
    end
    return qb
end


"""
    get_html_allblocks(blocks, strlen)

Given a list of blocks, find the interstitial blocks, tag them as `:REMAIN`
blocks and return a full list of blocks spanning the string.
"""
function get_html_allblocks(hblocks::Vector{<:HBlock}, strlen::Int)

    allblocks = Vector{Block}()
    lenhblocks = length(hblocks)
    next_hblock = iszero(lenhblocks) ? BIG_INT : hblocks[1].from

    head, hb_idx = 1, 1
    while (next_hblock < BIG_INT) & (head < strlen)
        # check if there's anything before head and next block and push
        (head < next_hblock) && push!(allblocks, remain(head, next_hblock-1))

        β = hblocks[hb_idx]
        push!(allblocks, β)
        head = β.to + 1
        hb_idx += 1
        next_hblock = (hb_idx > lenhblocks) ? BIG_INT : hblocks[hb_idx].from
    end
    # add final one if exists
    (head < strlen) && push!(allblocks, remain(head, strlen))
    return allblocks
end
