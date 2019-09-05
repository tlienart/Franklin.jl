"""
$(SIGNATURES)

Direct inline-style links are properly processed by Julia's Markdown processor but not:

* `[link title](https://www.google.com "Google's Homepage")`
* `[link title][some reference]` and later `[some reference]: http://www.reddit.com`
* `[link title]` and later `[link title]: https://www.mozilla.org`
"""
function find_and_fix_md_links(hs::String)::String
    # 1. find all occurences of -- [...]: link
    # NOTE at this point things have already been preprocessed so
    # [ was changed for &#91; and ] for &#93; making the regex very readable

    # here we're looking for [id]: link; 1=id 2=link
    m_link_defs = collect(eachmatch(r"&#91;((?:(?!&#93;).)*?)&#93;:\s(\S+)", hs))

    def_names = [def.captures[1] for def in m_link_defs]
    def_links = [def.captures[2] for def in m_link_defs]

    # here we're looking for [id] or [stuff][id] but not [id]:
    m_link_refs = collect(eachmatch(r"&#91;(.*?)&#93;(?!:)(&#91;(.*?)&#93;)?", hs))

    ref_names = [ifelse(ref.captures[3] === nothing || isempty(ref.captures[3]),
                    ref.captures[1], ref.captures[3]) for ref in m_link_refs]
    assoc_def = zeros(Int, length(m_link_refs)) # if 0 then nothing associated

    all_matches = vcat(m_link_defs, m_link_refs)

    # stop early if there's none of that stuff
    isempty(all_matches) && return hs

    sort!(all_matches, by = e -> e.offset)

    # now for every ref, try to find an associated def; if none
    # found then the relevant assoc_def will remain zero and that
    # ref will be left in place as it was
    for (i, refn) in enumerate(ref_names)
        # check that there's a corresponding def, otherwise ignore
        # we'll take the first match, it's up to the user not to have
        # multiple definitions with the same id
        j = findfirst(n->(n==refn), def_names)
        j === nothing || (assoc_def[i] = j)
    end

    # reconstruct the text
    h = IOBuffer()
    head = 1
    i = 0
    for m in all_matches
        # is it a def match or ref match?
        if length(m.captures) == 3
            i += 1
            ref = m
            # retrieve the index of the associated def
            j = assoc_def[i]
            iszero(j) && continue

            # write what's before
            offset = ref.offset
            (head < offset) && write(h, subs(hs, head, prevind(hs, offset)))

            # write the link
            if ref.captures[3] !== nothing && isempty(ref.captures[3])
                # [link text][] indicating that the link text is the title
                write(h, "<a href=\"$(def_links[j])\" title=\"$(ref_names[i])\">$(ref_names[i])</a>")
            else
                # either [link text] and [link text]: ... elsewhere or
                # [link text][id] and [id]: ... later
                write(h, html_ahref(def_links[j], ref.captures[1]))
            end
            # move the head
            head = nextind(hs, offset + length(ref.match) - 1)
        else
            def = m
            # just move the head, don't write the def
            head = nextind(hs, def.offset + length(def.match) - 1)
        end
    end
    strlen = lastindex(hs)
    (head < strlen) && write(h, subs(hs, head, strlen))

    return String(take!(h))
end
