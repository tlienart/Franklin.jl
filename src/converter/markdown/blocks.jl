"""
$(SIGNATURES)

Helper function for `convert_inter_html` that processes an extracted block
given a latex context `lxc` and returns the processed html that needs to be
plugged in the final html.
"""
function convert_block(β::AbstractBlock, lxdefs::Vector{LxDef})::AS
    # case for special characters / html entities
    β isa HTML_SPCH        && return ifelse(isempty(β.r), β.ss, β.r)
    # Return relevant interpolated string based on case
    βn = β.name
    βn ∈ MD_HEADER         && return convert_header(β, lxdefs)

    βn == :CODE_INLINE     && return html_code_inline(stent(β) |> htmlesc)
    βn == :CODE_BLOCK_LANG && return resolve_code_block(β.ss)
    βn == :CODE_BLOCK!     && return resolve_code_block(β.ss, shortcut=true)
    βn == :CODE_BLOCK      && return html_code(stent(β), "{{fill lang}}")
    βn == :CODE_BLOCK_IND  && return convert_indented_code_block(β.ss)

    βn == :ESCAPE          && return chop(β.ss, head=3, tail=3)
    βn == :FOOTNOTE_REF    && return convert_footnote_ref(β)
    βn == :FOOTNOTE_DEF    && return convert_footnote_def(β, lxdefs)
    βn == :LINK_DEF        && return ""

    βn == :DOUBLE_BRACE    && return β.ss # let HTML converter deal with it
    βn == :HORIZONTAL_RULE && return "<hr />"

    # Math block --> needs to call further processing to resolve possible latex
    βn ∈ MATH_BLOCKS_NAMES && return convert_math_block(β, lxdefs)

    # Div block --> need to process the block as a sub-element
    if βn == :DIV
        raw_cont = stent(β)
        cont     = convert_md(raw_cont, lxdefs;
                              isrecursive=true, has_mddefs=false,
                              nostripp=true) |> simplify_ps
        divname  = chop(otok(β).ss, head=2, tail=0)
        # parse @@c1,c2,c3 as class="c1 c2 c3"
        return html_div(replace(divname, ","=>" "), cont)
    end
    # default case, ignore block (should not happen)
    return ""
end
convert_block(β::LxObj, lxdefs::Vector{LxDef}) = resolve_lxobj(β, lxdefs)


"""
    MATH_BLOCKS_PARENS

Dictionary to keep track of how math blocks are fenced in standard LaTeX and
how these fences need to be adapted for compatibility with KaTeX. Each tuple
contains the number of characters to chop off the front and the back of the
maths expression (fences) as well as the KaTeX-compatible repl.
For instance, `\$ ... \$` will become `\\( ... \\)` chopping off 1 character at
the front and the back (`\$` sign).
"""
const MATH_BLOCKS_PARENS = LittleDict{Symbol, Tuple{Int,Int,String,String}}(
    :MATH_A     => ( 1,  1, "\\(", "\\)"),
    :MATH_B     => ( 2,  2, "\\[", "\\]"),
    :MATH_C     => ( 2,  2, "\\[", "\\]"),
    :MATH_I     => ( 4,  4, "", "")
    )


"""
$(SIGNATURES)

Helper function for the math block case of `convert_block` taking the inside of
a math block, resolving any latex command in it and returning the correct
syntax that KaTeX can render.
"""
function convert_math_block(β::OCBlock, lxdefs::Vector{LxDef})::String
    # try to find the block out of `MATH_BLOCKS_PARENS`, if not found, error
    pm = get(MATH_BLOCKS_PARENS, β.name) do
        throw(MathBlockError("Unrecognised math block name."))
    end

    # convert the inside, decorate with KaTex and return, also act if
    # if the math block is a "display" one (with a number)
    inner = chop(β.ss, head=pm[1], tail=pm[2])
    htmls = IOBuffer()
    if β.name ∉ [:MATH_A, :MATH_I]
        # NOTE: in the future if allow equation tags, then will need an `if`
        # here and only increment if there's no tag. For now just use numbers.

        # increment equation counter
        PAGE_EQREFS[PAGE_EQREFS_COUNTER] += 1

        # check if there's a label, if there is, add that to the dictionary
        matched = match(r"\\label{(.*?)}", inner)

        if !isnothing(matched)
            name   = refstring(matched.captures[1])
            write(htmls, "<a id=\"$name\" class=\"anchor\"></a>")
            inner  = replace(inner, r"\\label{.*?}" => "")
            # store the label name and associated number
            PAGE_EQREFS[name] = PAGE_EQREFS[PAGE_EQREFS_COUNTER]
        end
    end
    # assemble the katex decorators, the resolved content etc
    write(htmls, pm[3], convert_md_math(inner, lxdefs, from(β)), pm[4])
    return String(take!(htmls))
end


"""
$(SIGNATURES)

Helper function for the case of a header block (H1, ..., H6).
- gets a short string for the header anchor
- processes the actual header string as standard markdown (e.g. if has code)
- return the html.
"""
function convert_header(β::OCBlock, lxdefs::Vector{LxDef})::String
    hk    = lowercase(string(β.name)) # h1, h2, ...
    title = convert_md(content(β), lxdefs;
                       isrecursive=true, has_mddefs=false)
    rstitle = refstring(html_unescape(title))
    # check if the header has appeared before and if so suggest
    # an altered refstring; if that altered refstring also exist
    # (pathological case, see #241), then extend it with a letter
    # if that also exists (which would be really crazy) add a random
    # string
    keys_headers = keys(PAGE_HEADERS)
    if rstitle in keys_headers
        title, n, lvl = PAGE_HEADERS[rstitle]
        # then update the number of occurence
        PAGE_HEADERS[rstitle] = (title, n+1, lvl)
        # update the refstring, note the double _ (see refstring)
        rstitle *= "__$(n+1)"
        PAGE_HEADERS[rstitle] = (title, 0, parse(Int, hk[2]))
    else
        PAGE_HEADERS[rstitle] = (title, 1, parse(Int, hk[2]))
    end
    # return the title
    if globvar(:title_links)::Bool
        return html_hk(hk,
                       html_ahref_key(rstitle, title;
                                      class=locvar(:header_anchor_class)::String),
                       id=rstitle)
    end
    return html_hk(hk, title; id=rstitle)
end

"""
$(SIGNATURES)

Helper function for the indented code block case of `convert_block`.
"""
function convert_indented_code_block(ss::SubString)::String
    # 1. decrease indentation of all lines (either frontal \n\t or \n⎵⎵⎵⎵)
    code = replace(ss, r"\n(?:\t| {4})" => "\n")
    # 2. return; lang is a LOCAL_VARS that is julia by default and can be set
    sc = strip(code)
    isempty(sc) && return ""
    return html_code(sc, "{{fill lang}}")
end

"""
$(SIGNATURES)

Helper function to convert a `[^1]` into a html sup object with appropriate ref and backref.
"""
function convert_footnote_ref(β::Token)::String
    # β.ss is [^id]; extract id
    id = string(match(r"\[\^(.*?)\]", β.ss).captures[1])
    # add it to the list of refs unless it's been seen before
    pos = 0
    for (i, pri) in enumerate(PAGE_FNREFS)
        if pri == id
            pos = i
            break
        end
    end
    if pos == 0
        push!(PAGE_FNREFS, id)
        pos = length(PAGE_FNREFS)
    end
    return html_sup("fnref:$id", html_ahref("#fndef:$id", "[$pos]"; class="fnref"))
end

"""
$(SIGNATURES)

Helper function to convert a `[^1]: ...` into a html table for the def.
"""
function convert_footnote_def(β::OCBlock, lxdefs::Vector{LxDef})::String
    # otok(β) is [^id]:
    id = match(r"\[\^(.*?)\]:", otok(β).ss).captures[1]
    pos = 0
    for (i, pri) in enumerate(PAGE_FNREFS)
        if pri == id
            pos = i
            break
        end
    end
    if pos == 0
        # this was never referenced before, so probably best not to show it
        return ""
    end
    # need to process the content which could contain stuff
    ct = convert_md(content(β), lxdefs;
                       isrecursive=true, has_mddefs=false)
    """
    <table class="fndef" id="fndef:$id">
        <tr>
            <td class=\"fndef-backref\">$(html_ahref("#fnref:$id", "[$pos]"))</td>
            <td class=\"fndef-content\">$(ct)</td>
        </tr>
    </table>
    """
end
