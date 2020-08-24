"""
Convert a Franklin html string into a html string (i.e. replace `{{ ... }}`
blocks).
"""
function convert_html(hs::AS; isoptim::Bool=false)::String
    isempty(hs) && return hs

    (:convert_html, "input hs: '$hs'") |> logger
    (:convert_html, "hasmath/code: $(locvar.((:hasmath, :hascode)))") |> logger

    # Tokenize
    tokens = find_tokens(hs, HTML_TOKENS, HTML_1C_TOKENS)

    # Find hblocks ({{ ... }})
    hblocks, tokens = find_all_ocblocks(tokens, HTML_OCB)
    deactivate_inner_blocks!(hblocks, (:COMMENT, :SCRIPT))
    filter!(hb -> hb.name ∉ (:COMMENT, :SCRIPT), hblocks)

    # Find qblocks (qualify the hblocks)
    qblocks = qualify_html_hblocks(hblocks)

    fhs = process_html_qblocks(hs, qblocks)

    (:convert_html, "fhs (pre fix): '$fhs'") |> logger

    # See issue #204, basically not all markdown links are processed  as
    # per common mark with the JuliaMarkdown, so this is a patch that kind
    # of does
    if locvar(:reflinks)
        fhs = find_and_fix_md_links(fhs)
    end
    isempty(fhs) && return ""

    if !isempty(globvar("prepath")) && isoptim
        fhs = fix_links(fhs)
    end

    return String(fhs)
end


"""
$SIGNATURES

Return the HTML corresponding to a Franklin-Markdown string as well as all the
page variables. See also [`fd2html`](@ref) which only returns the html.
"""
function fd2html_v(st::AS; internal::Bool=false,
                   dir::String="", nop::Bool=false)::Tuple{String,Dict}
    FD_ENV[:SOURCE] = "input string"
    isempty(st) && return st
    if !internal
        empty!(ALL_PAGE_VARS)
        FOLDER_PATH[] = isempty(dir) ? mktempdir() : dir
        set_paths!()
        def_GLOBAL_LXDEFS!()
        def_GLOBAL_VARS!()
        FD_ENV[:CUR_PATH] = "index.md"
    end
    # corner case if `serve` is used and cleanup has emptied global vars
    !(@isdefined GLOBAL_VARS) || isempty(GLOBAL_VARS) && def_GLOBAL_VARS!()
    m = convert_md(st; isinternal=internal)
    h = convert_html(m)
    if nop && startswith(h, "<p>") && endswith(h, r"</p>\n?")
        # remove initial <p> and final </p>\n
        # note that this is unsafe in that these may not be related.
        h = replace(h, r"(^<p>|</p>\n?$)" => "")
    end
    return h, LOCAL_VARS
end

"""
    fd2html(s; kw)

Take a Markdown string and return the HTML that Franklin would produce for it.

# Keywords

* `internal=false`: if set to true, the current scope (in terms of page variables) will
                    be passed to process the String, otherwise the string will be processed
                    in an isolated scope.
* `dir=""`: if given and if `internal=false`, sets up a temporary dir for Franklin
            processing.
* `nop=false`: if set to true, check if the returned HTML string has a starting `<p>` and
               ending `</p>` and, if so, strips them off. This should be used with care:
               for simple strings this is likely to be ok but for strings which would
               contain multiple paragraphs (e.g. with headers) this may not work well.
"""
fd2html(s; kw...)::String = fd2html_v(s; kw...)[1]

# legacy JuDoc
jd2html = fd2html

"""
$SIGNATURES

Take a qualified html block stack and go through it, with recursive calling.
"""
function process_html_qblocks(hs::AS, qblocks::Vector{AbstractBlock},
                              head::Int=1, tail::Int=lastindex(hs))::String
    htmls = IOBuffer()
    head  = head # (sub)string index
    i     = 1    # qualified block index
    while i ≤ length(qblocks)
        β = qblocks[i]
        # write what's before the block
        fromβ = from(β)
        (head < fromβ) && write(htmls, subs(hs, head, prevind(hs, fromβ)))

        if β isa HTML_OPEN_COND
            content, head, i = process_html_cond(hs, qblocks, i)
            write(htmls, content)
        elseif β isa HFor
            content, head, i = process_html_for(hs, qblocks, i)
            write(htmls, content)
        # should not see an HEnd by itself --> error
        elseif β isa HEnd
            throw(HTMLBlockError("I found a lonely {{end}}."))
        # it's a function block, process it
        else
            write(htmls, convert_html_fblock(β))
            head = nextind(hs, to(β))
        end
        i += 1
    end
    # write whatever is left after the last block
    head ≤ tail && write(htmls, subs(hs, head, tail))
    return String(take!(htmls))
end


"""
    match_url(base, cand)

Try to match two url indicators.
"""
function match_url(base::AS, cand::AS)
    sbase = base[1] == '/' ? base[2:end] : base
    scand = cand[1] == '/' ? cand[2:end] : cand
    # joker-style syntax
    if endswith(scand, "/*")
        return startswith(sbase, scand[1:prevind(scand, lastindex(scand), 2)])
    elseif endswith(scand, "/")
        scand = scand[1:prevind(scand, lastindex(scand))]
    end
    return splitext(scand)[1] == sbase
end
