"""
    interweave_rep(html_string, splitter, replacements)

Finds blocks of a specific form (given by `splitter`) in the `html_string` and
return the `html_string` with each of the `replacements` instead of the blocks.
"""
function interweave_rep(html_string, splitter, replacements)
    split_html_string = split(html_string, splitter)
    html_string = split_html_string[1]
    for (c, rep) ∈ enumerate(replacements)
        html_string *= rep * split_html_string[c+1]
    end
    return html_string
end
