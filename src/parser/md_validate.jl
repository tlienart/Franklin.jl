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
            if m !== nothing
                if m.captures[1] !== nothing
                    # it's a def
                    tokens[i] = Token(:FOOTNOTE_DEF, τ.ss)
                else
                    # it's a ref, take and delete
                    push!(fn_refs, τ)
                    push!(rm, i)
                end
            else
                # delete
                push!(rm, i)
            end
        end
    end
    deleteat!(tokens, rm)
    return fn_refs
end

"""
$SIGNATURES

Verify that a given string corresponds to a well formed html entity.
"""
function validate_html_entity(ss::AS)
    match(r"&(?:[a-z0-9]+|#[0-9]{1,6}|#x[0-9a-f]{1,6});", ss) !== nothing
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
