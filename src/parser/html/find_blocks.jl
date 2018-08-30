#= NOTE / TODO
* in a conditional block, should make sure else is not followed by elseif
* no nesting of conditional blocks is allowed at the moment. This could
be done at later stage (needs balancing) or something but seems a bit overkill
at this point. This second point might fix the first one by making sure that
    HIf -> HElseIf / HElse / HEnd
    HElseIf -> HElseIf / HElse / HEnd
    HElse -> HEnd
=#


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
         active_tokens[i:j] .= false
    end
    return hblocks, tokens[active_tokens]
end


"""
    qualify_html_hblocks(blocks, s)

Given `{{ ... }}` blocks, identify what blocks they are and return a vector
of qualified blocks of type `<:HBlock`.
"""
function qualify_html_hblocks(blocks::Vector{Block}, s::String)
    qb = Vector{HBlock}(undef, length(blocks))
    for (i, β) ∈ enumerate(blocks)
        ts = s[β.from:β.to]
        # if block {{ if v }}
        m = match(HBLOCK_IF, ts)
        isnothing(m) ||
            (qb[i] = HIf(m.captures[1], β.from, β.to); continue)
        # else block {{ else }}
        m = match(HBLOCK_ELSE, ts)
        isnothing(m) ||
            (qb[i] = HElse(β.from, β.to); continue)
        # else if block {{ else if v }}
        m = match(HBLOCK_ELSE_IF, ts)
        isnothing(m) ||
            (qb[i] = HElseIf(m.captures[1], β.from, β.to); continue)
        # end block {{ end }}
        m = match(HBLOCK_END, ts)
        isnothing(m) ||
            (qb[i] = HEnd(β.from, β.to); continue)
        # function block {{ fname v1 v2 ... }}
        m = match(HBLOCK_FUN, ts)
        isnothing(m) ||
            (qb[i] = HFun(m.captures[1], split(m.captures[2]), β.from, β.to);
            continue)
        error("I found a HBlock that did not match anything, verify '$ts'")
    end
    return qb
end


"""
    find_html_cblocks(qblocks)

Given qualified blocks `HIf`, `HElse` etc, construct a vector of the
conditional blocks which contain the list of conditions etc.
No nesting is allowed at the moment.
"""
function find_html_cblocks(qblocks::Vector{<:HBlock})
    cblocks = Vector{HCond}()
    active_qblocks = ones(Bool, length(qblocks))
    i = 0
    while i < length(qblocks)
        i += 1
        β = qblocks[i]
        typeof(β) == HIf || continue

        # look forward until the next `{{ end }}` block
        k = findfirst(cβ -> (typeof(cβ) == HEnd), qblocks[i+1:end])
        isnothing(k) && error("Found an {{ if ... }} block but no matching {{ end }} block. Verify.")
        n_between = k - 1
        k += i

        vcond1 = β.vname
        vconds = Vector{String}()
        dofrom, doto = Vector{Int}(), Vector{Int}()
        from = β.from
        push!(dofrom, β.to + 1)

        for bi = 1:n_between
            β = qblocks[i+bi]
            if typeof(β) == HElseIf
                push!(doto, β.from - 1)
                push!(dofrom, β.to + 1)
                push!(vconds, β.vname)
            elseif typeof(β) == HElse
                # TODO, should check that there are no other HElseIf etc after
                push!(doto, β.from - 1)
                push!(dofrom, β.to + 1)
            end
        end
        endβ = qblocks[k]
        push!(doto, endβ.from - 1)
        push!(cblocks, HCond(vcond1, vconds, dofrom, doto, from, endβ.to))
        active_qblocks[i:k] .= false
        i = k
    end
    return cblocks, qblocks[active_qblocks]
end


"""
    get_html_allblocks(cblocks, strlen)

Given a list of blocks, find the interstitial blocks, tag them as `:REMAIN`
blocks and return a full list of blocks spanning the string.
"""
function get_html_allblocks(qblocks::Vector{<:HBlock}, hblocks::Vector{HCond},
                            strlen::Int)

    allblocks = Vector{Union{Block, <:HBlock, HCond}}()
    lenqb = length(qblocks)
    lenhb = length(hblocks)

    next_qblock = iszero(lenqb) ? BIG_INT : qblocks[1].from
    next_hblock = iszero(lenhb) ? BIG_INT : hblocks[1].from

    # check which block is next
    qb_or_hb = (next_qblock < next_hblock)
    next_idx = min(next_qblock, next_hblock)

    head, qb_idx, hb_idx = 1, 1, 1
    while (next_idx < BIG_INT) & (head < strlen)
        # check if there's anything before head and next block and push
        (head < next_idx) && push!(allblocks, remain(head, next_idx-1))

        if qb_or_hb # next block is qblock
            β = qblocks[qb_idx]
            push!(allblocks, β)
            head = β.to + 1
            qb_idx += 1
            next_qblock = (qb_idx > lenqb) ? BIG_INT : qblocks[qb_idx].from
        else # next block is hblock
            β = hblocks[hb_idx]
            push!(allblocks, β)
            head = β.to + 1
            hb_idx += 1
            next_hblock = (hb_idx > lenhb) ? BIG_INT : hblocks[hb_idx].from
        end

        # check which block is next
        qb_or_hb = (next_qblock < next_hblock)
        next_idx = min(next_qblock, next_hblock)
    end
    # add final one if exists
    (head < strlen) && push!(allblocks, remain(head, strlen))
    return allblocks
end
