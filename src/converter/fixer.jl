"""
$(SIGNATURES)

Direct inline-style links are properly processed by Julia's Markdown processor but not:

* `[link title][some reference]` and later `[some reference]: http://www.reddit.com`
* `[link title]` and later `[link title]: https://www.mozilla.org`
* (we don't either) `[link title](https://www.google.com "Google's Homepage")`
"""
function find_and_fix_md_links(hs::String)::String
    # 1. find all occurences of -- [...]: link

    # here we're looking for [id] or [id][] or [stuff][id] or ![stuff][id] but not [id]:
    # 1 > (&#33;)? == either ! or nothing
    # 2 > &#91;(.*?)&#93; == [...] inside of the brackets
    # 3 > (?:&#91;(.*?)&#93;)? == [...] inside of second brackets if there is such
    m_link_refs = collect(eachmatch(r"(&#33;)?&#91;(.*?)&#93;(?!:)(?:&#91;(.*?)&#93;)?", hs))

    # recuperate the appropriate name which has a chance to match def_names
    ref_names = [
        # no second bracket or empty second bracket ?
        # >> true then the id is in the first bracket
        # >> false then the id is in the second bracket
        ifelse(ref.captures[3] === nothing || isempty(ref.captures[3]),
                    ref.captures[2], # first bracket
                    ref.captures[3]) # second bracket
                    for ref in m_link_refs]

    # reconstruct the text
    h = IOBuffer()
    head = 1
    i = 0
    for (m, refn) in zip(m_link_refs, ref_names)
        # write what's before
        (head < m.offset) && write(h, subs(hs, head, prevind(hs, m.offset)))
        #
        def = get(PAGE_LINK_DEFS, refn) do
            ""
        end
        if isempty(def)
            # no def found --> just leave it as it was
            write(h, m.match)
        else
            if m.captures[3] !== nothing && isempty(m.captures[3])
                # [link text][] indicating that the link text is the title
                write(h, html_ahref(def, refn; title=refn))
            else
                if m.captures[1] !== nothing
                    # ![alt][id]
                    write(h, html_img(def, refn))
                else
                    # either [link text] and [link text]: ... elsewhere or
                    # [link text][id] and [id]: ... later
                    write(h, html_ahref(def, refn))
                end
            end
        end
        # move the head after the match
        head = nextind(hs, m.offset + length(m.match) - 1)
    end
    strlen = lastindex(hs)
    (head < strlen) && write(h, subs(hs, head, strlen))

    return String(take!(h))
end
