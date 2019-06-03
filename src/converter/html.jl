"""
$(SIGNATURES)

Convert a judoc html string into a html string (i.e. replace `{{ ... }}` blocks).
"""
function convert_html(hs::AbstractString, allvars::JD_VAR_TYPE, fpath::AbstractString="")::String
    # Tokenize
    tokens = find_tokens(hs, HTML_TOKENS, HTML_1C_TOKENS)

    # Find hblocks ({{ ... }})
    hblocks, tokens = find_all_ocblocks(tokens, HTML_OCB)
    filter!(hb -> hb.name != :COMMENT, hblocks)

    # Find qblocks (qualify the hblocks)
    qblocks = qualify_html_hblocks(hblocks)
    # Find overall conditional blocks (if ... elseif ... else ...  end)
    cblocks, qblocks = find_html_cblocks(qblocks)
    # Find conditional def blocks (isdef / isnotdef)
    cdblocks, qblocks = find_html_cdblocks(qblocks)
    # Find conditional page blocks (ispage / isnotpage)
    cpblocks, qblocks = find_html_cpblocks(qblocks)

    # Get the list of blocks to process
    hblocks = merge_blocks(qblocks, cblocks, cdblocks, cpblocks)

    # construct the final html
    htmls = IOBuffer()
    head = 1
    for (i, hb) ∈ enumerate(hblocks)
        fromhb = from(hb)
        (head < fromhb) && write(htmls, subs(hs, head, prevind(hs, fromhb)))
        write(htmls, convert_hblock(hb, allvars, fpath))
        head = nextind(hs, to(hb))
    end
    strlen = lastindex(hs)
    (head < strlen) && write(htmls, subs(hs, head, strlen))

    fhs = String(take!(htmls))
    # if it ends with </p>\n but doesn't start with <p>, chop it off
    # this may happen if the first element parsed is an ocblock (not text)
    δ = ifelse(endswith(fhs, "</p>\n") && !startswith(fhs, "<p>"), 5, 0)

    isempty(fhs) && return ""
    return String(chop(fhs, tail=δ))
end
