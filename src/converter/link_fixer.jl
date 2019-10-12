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
    rx = r"(&#33;)?&#91;(.*?)&#93;(?!:)(?:&#91;(.*?)&#93;)?"
    m_link_refs = collect(eachmatch(rx, hs))

    # recuperate the appropriate id which has a chance to match def_names
    ref_names = [
        # no second bracket or empty second bracket ?
        # >> true then the id is in the first bracket   A --> [id] or [id][]
        # >> false then the id is in the second bracket B --> [...][id]
        ifelse(isnothing(ref.captures[3]) || isempty(ref.captures[3]),
                    ref.captures[2],    # A. first bracket
                    ref.captures[3])    # B. second bracket
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
            if !isnothing(m.captures[1])
                # CASE: ![alt][id] --> image
                write(h, html_img(def, refn))
            else
                # It's a link
                if isnothing(m.captures[3]) || isempty(m.captures[3])
                    # CASE: [id] or [id][] the id is also the link text
                    write(h, html_ahref(def, refn))
                else
                    # It's got a second, non-empty bracket
                    # CASE: [name][id]
                    name = m.captures[2]
                    write(h, html_ahref(def, name))
                end
            end
        end
        # move the head after the match
        head = nextind(hs, m.offset + lastindex(m.match) - 1)
    end
    strlen = lastindex(hs)
    (head ≤ strlen) && write(h, subs(hs, head, strlen))

    return String(take!(h))
end


"""
$(SIGNATURES)

for a project website, for instance `username.github.io/project/` all paths should eventually
be pre-prended with `/project/`. This would happen just before you publish the website.
"""
function fix_links(pg::String)::String
    pp = strip(GLOBAL_PAGE_VARS["prepath"].first, '/')
    ss = SubstitutionString("\\1=\"/$(pp)/")
    return replace(pg, r"(src|href)\s*?=\s*?\"\/" => ss)
end
