"""
$SIGNATURES

Find footnotes refs and defs and eliminate the ones that don't verify the
appropriate regex. For a footnote ref: `\\[\\^[a-zA-Z0-0]+\\]` and
`\\[\\^[a-zA-Z0-0]+\\]:` for the def.
"""
function validate_footnotes!(tokens::Vector{Token})
    fn_refs = Vector{Token}()
    rm      = Int[]
    for (i, τ) in enumerate(tokens)
        τ.name == :FOOTNOTE_REF || continue
        # footnote ref [^1]:
        m = match(r"^\[\^[a-zA-Z0-9]+\](:)?$", τ.ss)
        if !isnothing(m)
            if !isnothing(m.captures[1])
                # it's a def
                tokens[i] = Token(:FOOTNOTE_DEF, τ.ss)
            end
            # otherwise it's a ref, leave as is
        else
            # delete
            push!(rm, i)
        end
    end
    deleteat!(tokens, rm)
    return nothing
end

"""
$SIGNATURES

Verify that a given string corresponds to a well formed html entity.
"""
function validate_html_entity(ss::AS)
    !isnothing(match(r"&(?:[a-z0-9]+|#[0-9]{1,6}|#x[0-9a-f]{1,6});", ss))
end

"""
$(SIGNATURES)

Given a candidate header block, check that the opening `#` is at the start of a
line, otherwise ignore the block.
"""
function validate_headers!(tokens::Vector{Token})::Nothing
    isempty(tokens) && return
    s = str(tokens[1].ss) # does not allocate
    rm = Int[]
    for (i, τ) in enumerate(tokens)
        τ.name in MD_HEADER_OPEN || continue
        # check if it overlaps with the first character
        fromτ = from(τ)
        fromτ == 1 && continue
        # otherwise check if the previous character is a linereturn
        prevc = s[prevind(s, fromτ)]
        prevc == '\n' && continue
        push!(rm, i)
    end
    deleteat!(tokens, rm)
    return
end

postprocess_link(s::String) = replace(r"")

"""
$(SIGNATURES)

Keep track of link defs. Deactivate any blocks that is within the span of
a link definition (see issue #314).
"""
function validate_and_store_link_defs!(blocks::Vector{OCBlock})::Nothing
    isempty(blocks) && return
    rm = Int[]
    parent = str(blocks[1])
    for (i, β) in enumerate(blocks)
        if β.name == :LINK_DEF
            # incremental backward look until we find a `[` or a `\n`
            # if `\n` (or start of string) first, discard
            ini  = prevind(parent, from(β))
            k    = ini
            char = '\n'
            while k ≥ 1
                char = parent[k]
                char ∈ ('[','\n') && break
                k = prevind(parent, k)
            end
            if char == '['
                # redefine the full block
                ftk = Token(:FOO,subs(""))
                # we have a [id]: lk add it to PAGE_LINK_DEFS
                id = subs(parent, nextind(parent, k), ini)
                # issue #266 in case there's formatting in the link
                id = fd2html(id, internal=true)
                id = replace(id, r"^<p>"=>"")
                id = replace(id, r"<\/p>\n$"=>"")
                lk = β |> content |> strip |> string
                PAGE_LINK_DEFS[id] = lk
                # replace the block by a full one so that it can be fully
                # discarded in the process of md blocks
                blocks[i] = OCBlock(:LINK_DEF, ftk=>ftk, subs(parent, k, to(β)))
            else
                # discard
                push!(rm, i)
            end
        end
    end
    isempty(rm) || deleteat!(blocks, rm)
    # cleanup: deactivate any block that it's in the span of a link def
    spans = [(from(ld), to(ld)) for ld in blocks if ld.name == :LINK_DEF]
    if !isempty(spans)
        for (i, block) in enumerate(blocks)
            # if it's in one of the span, discard
            curspan = (from(block), to(block))
            # early stopping if before all ld or after all of them
            curspan[2] < spans[1][1]   && continue
            curspan[1] > spans[end][2] && continue
            # go over each span break as soon as it's in
            for span in spans
                if span[1] < curspan[1] && curspan[2] < span[2]
                    push!(rm, i)
                    break
                end
            end
        end
    end
    isempty(rm) || deleteat!(blocks, rm)
    return nothing
end
