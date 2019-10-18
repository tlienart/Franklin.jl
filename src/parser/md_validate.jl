"""
$SIGNATURES

Find footnotes refs and defs and eliminate the ones that don't verify the appropriate regex.
For a footnote ref: `\\[\\^[a-zA-Z0-0]+\\]` and `\\[\\^[a-zA-Z0-0]+\\]:` for the def.
"""
function validate_footnotes!(tokens::Vector{Token})
    fn_refs = Vector{Token}()
    rm      = Int[]
    for (i, τ) in enumerate(tokens)
        if τ.name == :FOOTNOTE_REF
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

Given a candidate header block, check that the opening `#` is at the start of a line, otherwise
ignore the block.
"""
function validate_header_block(β::OCBlock)::Bool
    # skip non-header blocks
    β.name ∈ MD_HEADER || return true
    # if it's a header block, have a look at the opening token
    τ = otok(β)
    # check if it overlaps with the first character
    from(τ) == 1 && return true
    # otherwise check if the previous character is a linereturn
    s = str(β.ss) # does not allocate
    prevc = s[prevind(str(β.ss), from(τ))]
    prevc == '\n' && return true
    return false
end

postprocess_link(s::String) = replace(r"")

"""
$(SIGNATURES)

Keep track of link defs.
"""
function validate_and_store_link_defs!(blocks::Vector{OCBlock})::Nothing
    isempty(blocks) && return
    rm = Int[]
    parent = str(blocks[1])
    for (i, β) in enumerate(blocks)
        if β.name == :LINK_DEF
            # incremental backward look until we find a `[` or a `\n` if `\n` first, discard
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
                id = jd2html(id, internal=true)
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
    deleteat!(blocks, rm)
    return nothing
end
