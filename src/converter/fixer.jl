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
    # [ was changed for &#91; and ] for &#93; and ! for &#33; making
    # the regexes very readable...

    # here we're looking for [id]: link; 1=id 2=link
    m_link_defs = collect(eachmatch(r"&#91;((?:(?!&#93;).)*?)&#93;:\s((?:(?!\<\/p\>)\S)+)", hs))

    def_names = [def.captures[1] for def in m_link_defs]
    def_links = [def.captures[2] for def in m_link_defs]

    # here we're looking for [id] or [stuff][id] or ![stuff][id] but not [id]:
    m_link_refs = collect(eachmatch(r"(&#33;)?&#91;(.*?)&#93;(?!:)(?:&#91;(.*?)&#93;)?", hs))

    # recuperate the appropriate name which has a chance to match def_names
    ref_names = [ifelse(ref.captures[3] === nothing || isempty(ref.captures[3]),
                    ref.captures[2], ref.captures[3]) for ref in m_link_refs]

    # allocate a vector of associated definitions for each ref; if 0 nothing matched
    assoc_def = zeros(Int, length(m_link_refs))

    # aggregate and sort all matches
    all_matches = vcat(m_link_defs, m_link_refs)
    # stop early if there's none of that stuff
    isempty(all_matches) && return hs
    # sort by offset
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
        # write what's before
        (head < m.offset) && write(h, subs(hs, head, prevind(hs, m.offset)))
        # is it a def match or ref match?
        if length(m.captures) == 3 # ref match
            i  += 1
            ref = m
            # retrieve the index of the associated def
            j = assoc_def[i]
            if iszero(j)
                write(h, m.match)
            else
                # write the link
                if ref.captures[3] !== nothing && isempty(ref.captures[3])
                    # [link text][] indicating that the link text is the title
                    write(h, html_ahref(def_links[j], ref_names[i]; title=ref_names[i]))
                else
                    if ref.captures[1] !== nothing # ![alt][id]
                        write(h, html_img(def_links[j], ref.captures[2]))
                    else
                        # either [link text] and [link text]: ... elsewhere or
                        # [link text][id] and [id]: ... later
                        write(h, html_ahref(def_links[j], ref.captures[2]))
                    end
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
