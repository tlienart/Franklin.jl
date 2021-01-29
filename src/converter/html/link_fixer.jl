"""
$(SIGNATURES)

Direct inline-style links are properly processed by Julia's Markdown processor but not:

* `[link title][some reference]` and later `[some reference]: http://www.reddit.com`
* `[link title]` and later `[link title]: https://www.mozilla.org`
* `[link title](https://www.google.com "Google's Homepage")` (we don't either)
"""
function find_and_fix_md_links(hs::String)::String
    # 1. find all occurences of things that look like links
    m_link_refs = collect(eachmatch(ESC_LINK_PAT, hs))

    # recuperate the appropriate id which has a chance to match def_names
    ref_names = [
        # no second bracket or empty second bracket ?
        # >> true then the id is in the first bracket   A --> [id] or [id][]
        # >> false then the id is in the second bracket B --> [...][id]
        ifelse(isnothing(ref.captures[3]) ||
               isempty(ref.captures[3]),
                         ref.captures[2], # A. first bracket
                         ref.captures[3]) # B. second bracket
                #
                for ref in m_link_refs]

    isempty(ref_names) || (ref_names = strip.(ref_names))

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

For a project website, for instance `username.github.io/project/` all relative
paths should eventually be pre-pended with `/project/`. This would happen just
before you publish the website (see `optimize` or `publish`).
"""
function fix_links(pg::String)::String
    prepath = globvar(:prepath)
    isempty(prepath) && return pg
    pp = strip(prepath, '/')
    ss = SubstitutionString("\\1=\"/$(pp)/")
    # replace things that look like href="/..." with href="/$prepath/..."
    return replace(pg, PREPATH_FIX_PAT => ss)
end
