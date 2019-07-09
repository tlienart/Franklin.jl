"""
$(SIGNATURES)

Convenience function to call the base markdown to html converter on "simple" strings (i.e. strings
that don't need to be further considered and don't contain anything else than markdown tokens).
The boolean `stripp` indicates whether to remove the inserted `<p>` and `</p>` by the base markdown
processor, this is relevant for things that are parsed within latex commands etc.
"""
function md2html(ss::AbstractString, stripp::Bool=false)::AbstractString
    isempty(ss) && return ss

    # Use the base Markdown -> Html converter and post process headers
    partial = ss |> fix_inserts |> Markdown.parse |> Markdown.html |> fix_lineskips

    # In some cases, base converter adds <p>...</p>\n which we might not want
    stripp || return partial
    startswith(partial, "<p>")    && (partial = chop(partial, head=3))
    endswith(partial,   "</p>")   && return chop(partial, tail=4)
    endswith(partial,   "</p>\n") && return chop(partial, tail=5)
    return partial
end


"""
$(SIGNATURES)

Convenience function to check if `idx` is smaller than the length of `v`, if it is, then return the starting point of `v[idx]` (via `from`), otherwise return `BIG_INT`.
"""
from_ifsmaller(v::Vector, idx::Int, len::Int)::Int = (idx > len) ? BIG_INT : from(v[idx])


"""
$(SIGNATURES)

Since divs are recursively processed, once they've been found, everything inside them needs to be
deactivated and left for further re-processing to avoid double inclusion.
"""
function deactivate_divs(blocks::Vector{OCBlock})::Vector{OCBlock}
    active_blocks = ones(Bool, length(blocks))
    for (i, β) ∈ enumerate(blocks)
        fromβ, toβ = from(β), to(β)
        active_blocks[i] || continue
        if β.name == :DIV
            innerblocks = findall(b -> (fromβ < from(b) < toβ), blocks)
            active_blocks[innerblocks] .= false
        end
    end
    return blocks[active_blocks]
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


"""
$(SIGNATURES)

The insertion token have whitespaces around them: ` ##JDINSERT## `, this mostly helps but causes
a problem when combined with italic or bold markdown mode since `_blah_` works but not `_ blah _`.
This function looks for any occurrence of `[\\*_] ##JDINSERT##` or the opposite and removes the
extraneous whitespace.
"""
fix_inserts(s::AbstractString)::String =
    replace(replace(s, r"([\*_]) ##JDINSERT##" => s"\1##JDINSERT##"),
                       r"##JDINSERT## ([\*_])" => s"##JDINSERT##\1")


"""
$(SIGNATURES)

Allow the use of latex-like `\\` to force a line skip.
"""
fix_lineskips(s::AbstractString)::String = replace(s, r"\\\\" => "<br/>")
