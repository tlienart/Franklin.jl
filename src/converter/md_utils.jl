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
    partial = ss |> fix_inserts |> Markdown.parse |> Markdown.html |> make_header_refs

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

By default the Base Markdown to HTML converter simply converts `## ...` into headers but not
linkable ones; this is annoying for generation of table of contents etc (and references in
general) so this function does just that.
"""
function make_header_refs(h::String)::String
    io = IOBuffer()
    head = 1
    for m ∈ eachmatch(r"<h([1-6])>(.*?)</h[1-6]>", h)
        write(io, subs(h, head:m.offset-1))
        level = m.captures[1]
        name  = m.captures[2]
        ref   = refstring(name)
        write(io, "<h$level><a id=\"$ref\" href=\"#$ref\">$name</a></h$level>")
        head = m.offset + lastindex(m.match)
    end
    write(io, subs(h, head:lastindex(h)))
    return String(take!(io))
end
