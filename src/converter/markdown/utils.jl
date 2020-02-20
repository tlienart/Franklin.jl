"""
$(SIGNATURES)

Convenience function to call the base markdown to html converter on "simple" strings (i.e. strings
that don't need to be further considered and don't contain anything else than markdown tokens).
The boolean `stripp` indicates whether to remove the inserted `<p>` and `</p>` by the base markdown
processor, this is relevant for things that are parsed within latex commands etc.
"""
function md2html(ss::AS; stripp::Bool=false)::AS
    # if there's nothing, return that...
    isempty(ss) && return ss
    # Use Julia's Markdown parser followed by Julia's MD->HTML conversion
    partial = ss |> fix_inserts |> Markdown.parse |> Markdown.html
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

The insertion token have whitespaces around them: ` ##FDINSERT## `, this mostly helps but causes
a problem when combined with italic or bold markdown mode since `_blah_` works but not `_ blah _`.
This function looks for any occurrence of `[\\*_] ##FDINSERT##` or the opposite and removes the
extraneous whitespace.
"""
fix_inserts(s::AS)::String =
    replace(replace(s, r"([\*_]) ##FDINSERT##" => s"\1##FDINSERT##"),
                       r"##FDINSERT## ([\*_])" => s"##FDINSERT##\1")

"""
$(SIGNATURES)

Takes a list of tokens and deactivate tokens that happen to be in a multi-line
md-def. Used in [`convert_md`](@ref).
"""
function preprocess_candidate_mddefs!(tokens::Vector{Token})
    isempty(tokens) && return nothing
    # process:
    # 1. find a MD_DEF_OPEN token
    # 2. Look for the first LINE_RETURN (proper)
    # 3. try to parse the content with Meta.parse. If it completely fails,
    # error, otherwise consider the  span of the first ok expression and
    # discard all tokens within its span leaving effectively just the
    # opening MD_DEF_OPEN and closing LINE_RETURN
    from_to_list = Pair{Int,Int}[]
    i = 0
    while i < length(tokens)
        i += 1
        τ  = tokens[i]
        τ.name == :MD_DEF_OPEN || continue
        # look ahead stopping with the first LINE_RETURN
        j = findfirst(τc -> τc.name ∈ (:LINE_RETURN, :EOS), tokens[i+1:end])
        if j !== nothing
            e = i+j
            # discard if it's a single line
            any(τx -> τx.name == :LR_INDENT, tokens[i:e]) || continue
            push!(from_to_list, (i => e))
        end
    end
    remove = Int[]
    s = str(first(tokens))
    for (i, j) in from_to_list
        si = nextind(s, to(tokens[i]))
        sj = prevind(s, from(tokens[j]))
        sc = subs(s, si, sj)
        ex, pos = Meta.parse(sc, 1)

        # find where's the first character after the effective end of the
        # definition (right-strip)
        str_expr = subs(s, si, si + prevind(sc, pos))
        stripped = strip(str_expr)
        start_id = findfirst(c -> c == stripped[1], str_expr)
        last_id  = prevind(str_expr, start_id + length(stripped))

        # find the first token after si + next_id - 1 and discard what's before
        c = findfirst(k -> from(tokens[k]) > si + last_id - 1, i+1:j)
        # we discard everything between i+1 and i+c-1 (we want to keep i+c)
        if !isnothing(c)
            append!(remove, i+1:i+c-1)
        end
    end
    deleteat!(tokens, remove)
    return nothing
end
