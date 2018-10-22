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

Find blocks surrounded by `{{...}}` and create `Block(:H_BLOCK)`
"""
function find_html_hblocks(tokens::Vector{Token})
    #
    ntokens = length(tokens)
    active_tokens = ones(Bool, length(tokens))
    # storage for the blocks `{...}`
    hblocks = Vector{OCBlock}()
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
             inbalance += ocbalance(tokens[j], :H_BLOCK_OPEN => :H_BLOCK_CLOSE)
         end
         (inbalance > 0) && error("I found at least one open curly brace that is not closed properly. Verify.")
         push!(hblocks, OCBlock(:H_BLOCK, τ => tokens[j]))
         # remove processed tokens and mark inner tokens as inactive!
         # these will be re-processed in recursion
         active_tokens[i:j] .= false
    end
    return hblocks, tokens[active_tokens]
end


"""
    qualify_html_hblocks(blocks)

Given `{{ ... }}` blocks, identify what blocks they are and return a vector
of qualified blocks of type `AbstractBlock`.
"""
function qualify_html_hblocks(blocks::Vector{OCBlock})
    qb = Vector{AbstractBlock}(undef, length(blocks))
    for (i, β) ∈ enumerate(blocks)
        # if block {{ if v }}
        m = match(HBLOCK_IF, β.ss)
        isnothing(m) ||
            (qb[i] = HIf(β.ss, m.captures[1]); continue)
        # else block {{ else }}
        m = match(HBLOCK_ELSE, β.ss)
        isnothing(m) ||
            (qb[i] = HElse(β.ss); continue)
        # else if block {{ elseif v }}
        m = match(HBLOCK_ELSEIF, β.ss)
        isnothing(m) ||
            (qb[i] = HElseIf(β.ss, m.captures[1]); continue)
        # end block {{ end }}
        m = match(HBLOCK_END, β.ss)
        isnothing(m) ||
            (qb[i] = HEnd(β.ss); continue)
        # ifdef block
        m = match(HBLOCK_IFDEF, β.ss)
        isnothing(m) ||
            (qb[i] = HIfDef(β.ss, m.captures[1]); continue)
        # ifndef block
        m = match(HBLOCK_IFNDEF, β.ss)
        isnothing(m) ||
            (qb[i] = HIfNDef(β.ss, m.captures[1]); continue)
        # function block {{ fname v1 v2 ... }}
        m = match(HBLOCK_FUN, β.ss)
        isnothing(m) ||
            (qb[i] = HFun(β.ss, m.captures[1], split(m.captures[2])); continue)
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
function find_html_cblocks(qblocks::Vector{AbstractBlock})
    cblocks = Vector{HCond}()
    isempty(qblocks) && return cblocks, qblocks
    active_qblocks = ones(Bool, length(qblocks))
    i = 0
    while i < length(qblocks)
        i += 1
        β = qblocks[i]
        (typeof(β) == HIf) || continue

        # look forward until the next `{{ end }}` block
        k = findfirst(cβ -> (typeof(cβ) == HEnd), qblocks[i+1:end])
        isnothing(k) && error("Found an {{ if ... }} block but no matching {{ end }} block. Verify.")
        n_between = k - 1
        k += i

        initial_cond = β.vname
        secondary_conds = Vector{String}()
        afrom, ato = Vector{Int}(), Vector{Int}()
        push!(afrom, to(β) + 1)

        for bi ∈ 1:n_between
            β = qblocks[i + bi]
            if typeof(β) == HElseIf
                push!(ato,   from(β) - 1)
                push!(afrom, to(β) + 1)
                push!(secondary_conds, β.vname)
            elseif typeof(β) == HElse
                # TODO, should check that there are no other HElseIf etc after
                push!(ato,   from(β) - 1)
                push!(afrom, to(β) + 1)
            end
        end
        stβ, endβ = qblocks[i], qblocks[k]
        hcondss = subs(str(stβ), from(stβ), to(endβ))
        push!(ato, from(endβ) - 1)

        # assemble the actions
        actions = [subs(str(stβ), afrom[i], ato[i]) for i ∈ eachindex(afrom)]
        # form the hcond
        push!(cblocks, HCond(hcondss, initial_cond, secondary_conds, actions))
        active_qblocks[i:k] .= false
        i = k
    end
    return cblocks, qblocks[active_qblocks]
end


"""
    find_html_cdblocks(qblocks)

Given qualified blocks `HIfDef` or `HIfNDef` build a conditional def block.
"""
function find_html_cdblocks(qblocks::Vector{AbstractBlock})
    cdblocks = Vector{HCondDef}()
    isempty(qblocks) && return cdblocks, qblocks
    active_qblocks = ones(Bool, length(qblocks))
    i = 0
    while i < length(qblocks)
        i += 1
        β = qblocks[i]
        (typeof(β) ∈ [HIfDef, HIfNDef]) || continue
        # look forward until next `{{end}} block
        k = findfirst(cβ -> (typeof(cβ) == HEnd), qblocks[i+1:end])
        isnothing(k) && error("Found an {{ if(n)def ...}} block but no matching {{end}} block. Verify.")
        k += i
        endβ = qblocks[k]
        hcondss = subs(str(β), from(β), to(endβ))
        action = subs(str(β), to(β)+1, from(endβ)-1)
        push!(cdblocks, HCondDef(β, hcondss, action))
        active_qblocks[i:k] .= false
        i = k
    end
    return cdblocks, qblocks[active_qblocks]
end
