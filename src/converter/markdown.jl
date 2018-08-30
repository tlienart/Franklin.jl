const JD_INSERT = "##JDINSERT##"
const PAT_JD_INSERT = Regex(JD_INSERT)
const LEN_JD_INSERT = length(JD_INSERT)


"""
    md2html(s, stripp)

Convenience function to call the base markdown to html converter on "simple"
strings (i.e. strings that don't need to be further considered and don't
contain anything else than markdown tokens).
The boolean `stripp` indicates whether to remove the inserted `<p>` and `</p>`
by the base markdown processor, this is relevant for things that are parsed
within latex commands etc.
Note: it may get fed with a `SubString` whence the use of `AbstractString`.
"""
function md2html(s::AbstractString, stripp::Bool=false)
    isempty(s) && return s
    tmp = Markdown.html(Markdown.parse(s))
    stripp && return chop(tmp, head=3, tail=5) # remove <p>...</p>\n
    return tmp
end


"""
    form_inter_md(mds, xblocks, lxdefs)

Form an intermediate MD file where special blocks are replaced by a marker
(`JD_INSERT`) indicating that a piece will need to be plugged in there later.
"""
function form_inter_md(mds::AbstractString, xblocks::Vector{<:AbstractBlock},
                        lxdefs::Vector{LxDef})

    # final character is the EOS character
    strlen = lastindex(mds) - 1
    pieces = Vector{AbstractString}()

    lenxb = length(xblocks)
    lenlx = length(lxdefs)

    # check when the next xblock is
    next_xblock = iszero(lenxb) ? BIG_INT : xblocks[1].from

    # check when the next lxblock is, extra work because there may be lxdefs
    # passed through in *context* (i.e. that do not appear in mds) therefore
    # searcg first lxdef actually in mds (nothing if lxdefs is empty)
    first_lxd = findfirst(δ -> (δ.from > 0), lxdefs)
    next_lxdef = isnothing(first_lxd) ? BIG_INT : lxdefs[first_lxd].from

    # check which block is next
    xb_or_lx = (next_xblock < next_lxdef)
    next_idx = min(next_xblock, next_lxdef)

    head, xb_idx, lx_idx = 1, 1, first_lxd
    while (next_idx < BIG_INT) & (head < strlen)
        # check if there's anything before head and next block and push
        (head < next_idx) && push!(pieces, subs(mds, head, next_idx-1))
        # check whether it's a xblock first or a newcommand first
        if xb_or_lx # it's a xblock --> push
            push!(pieces, JD_INSERT)
            head = xblocks[xb_idx].to + 1
            xb_idx += 1
            next_xblock = (xb_idx > lenxb) ? BIG_INT : xblocks[xb_idx].from
        else # it's a newcommand --> no push
            head = lxdefs[lx_idx].to + 1
            lx_idx += 1
            next_lxdef = (lx_idx > lenlx) ? BIG_INT : lxdefs[lx_idx].from
        end
        # check which block is next
        xb_or_lx = (next_xblock < next_lxdef)
        next_idx = min(next_xblock, next_lxdef)
    end
    # add final one if exists
    (head <= strlen) && push!(pieces, chop(mds, head=head-1, tail=1))
    return prod(pieces)
end


"""
    convert_md(mds, pre_lxdefs; isconfig, has_mddefs)

Convert a judoc markdown file into a judoc html.
"""
function convert_md(mds::AbstractString, pre_lxdefs=Vector{LxDef}();
                    isrecursive=false, isconfig=false, has_mddefs=true)
    # Tokenize
    tokens = find_tokens(mds, MD_TOKENS, MD_1C_TOKENS)
    # Deactivate tokens within code blocks
    tokens = deactivate_xblocks(tokens, MD_EXTRACT)
    # Find brace blocks
    bblocks, tokens = find_md_bblocks(tokens)
    # Find newcommands (latex definitions)
    lxdefs, tokens = find_md_lxdefs(mds, tokens, bblocks)
    # if any lxdefs are given in the context, merge them. `pastdef!` specifies
    # that the definitions appear "earlier" by marking the `.from` at 0
    lprelx = length(pre_lxdefs)
    (lprelx > 0) && (lxdefs = cat(pastdef!.(pre_lxdefs), lxdefs, dims=1))

    # Find blocks to extract
    xblocks, tokens = find_md_xblocks(tokens)
    # Find lxcoms
    lxcoms, tokens = find_md_lxcoms(mds, tokens, lxdefs, bblocks)
    # Merge the lxcoms and xblocks -> list of things to insert
    blocks2insert = merge_xblocks_lxcoms(xblocks, lxcoms)

    if has_mddefs
        # Process MD_DEF blocks
        mdd = filter(b -> (b.name == :MD_DEF), xblocks)
        assignments = Vector{Pair{String, String}}(undef, length(mdd))
        for i ∈ eachindex(mdd)
            m = match(MD_DEF_PAT, mds[mdd[i].from:mdd[i].to])
            isnothing(m) && warn("Found delimiters for an @def environment but I couldn't match it, verify $(mds[mdd[i].from:mdd[i].to]). Ignoring.")
            assignments[i] = String(m.captures[1]) => String(m.captures[2])
        end
        # Assign as appropriate
        if isconfig
            isempty(assignments) || set_vars!(JD_GLOB_VARS, assignments)
            isempty(lxdefs) || push!(JD_GLOB_LXDEFS, lxdefs)
            # no more processing required
            return nothing
        end
        # create variable dictionary for the page
        jd_vars = merge(JD_GLOB_VARS, copy(JD_LOC_VARS))
        set_vars!(jd_vars, assignments)
    end

    # form intermediate markdown + html
    inter_md = form_inter_md(mds, blocks2insert, lxdefs)
    inter_html = md2html(inter_md, isrecursive)
    # plug resolved blocks in partial html to form the final html
    lxcontext = LxContext(lxcoms, lxdefs, bblocks)
    hstring = convert_inter_html(inter_html, mds, blocks2insert, lxcontext)
    # Return the string + judoc variables if relevant
    return hstring, (has_mddefs ? jd_vars : nothing)
end


"""
    convert_md_math(mds, lxdefs)

Same as `convert_md` except tailored for conversion of the inside of a
math block (no command definitions, restricted tokenisation to latex tokens).
"""
function convert_md_math(mds::AbstractString, lxdefs=Vector{LxDef}())
    # tokenize with restricted set
    tokens = find_tokens(mds, MD_TOKENS_LX, MD_1C_TOKENS_LX)
    bblocks, tokens = find_md_bblocks(tokens)
    # in a math environment > pass a bool to indicate it
    lxcoms, tokens = find_md_lxcoms(mds, tokens, lxdefs, bblocks, true)
    # form the string (see `form_inter_md`, similar but fewer conditions)
    strlen = lastindex(mds) - 1
    pieces = Vector{AbstractString}()
    lenlxc = length(lxcoms)
    next_lxcom = iszero(lenlxc) ? BIG_INT : lxcoms[1].from
    head, lxcom_idx = 1, 1
    while (next_lxcom < BIG_INT) & (head < strlen)
        (head < next_lxcom) && push!(pieces, subs(mds, head, next_lxcom-1))
        push!(pieces, resolve_lxcom(lxcoms[lxcom_idx], mds, lxdefs, true))
        head = lxcoms[lxcom_idx].to + 1
        lxcom_idx += 1
        next_lxcom = (lxcom_idx > lenlxc) ? BIG_INT : lxcoms[lxcom_idx].from
    end
    (head <= strlen) && push!(pieces, chop(mds, head=head-1, tail=1))
    return prod(pieces)
end


"""
    convert_inter_md(intermd, refmd, xblocks, coms, lxdefs, bblocks)

Take a partial markdown string with the `JD_INSERT` marker and plug in the --
appropriately processed -- block.
"""
function convert_inter_html(interhtml::AbstractString, refmd::AbstractString,
                            blocks2insert::Vector{<:AbstractBlock},
                            lxcontext::LxContext)

    # Find the JD_INSERT indicators
    allmatches = collect(eachmatch(PAT_JD_INSERT, interhtml))
    pieces = Vector{AbstractString}()
    strlen = lastindex(interhtml)
    # construct the pieces of the final html in order, gradually processing
    # the blocks to insert.
    head = 1
    for (i, m) ∈ enumerate(allmatches)
        (head < m.offset) && push!(pieces, subs(interhtml, head, m.offset-1))
        head = m.offset + LEN_JD_INSERT
        # store the resolved block
        push!(pieces, convert_block(blocks2insert[i], refmd, lxcontext))
    end
    # store whatever is after the last JD_INSERT if anything
    (head < strlen) && push!(pieces, subs(interhtml, head, strlen))
    # return the full string
    return prod(pieces)
end


"""
    convert_block(β, s, lxcontext)

Helper function for `convert_inter_html` that processes an extracted block and
return the processed html that needs to be plugged in the final html.
"""
function convert_block(β::AbstractBlock, s::AbstractString,
                       lxcontext::LxContext)

    # Latex commands *outside* a math block
    (typeof(β) == LxCom) && return resolve_lxcom(β, s, lxcontext.lxdefs)
    # Not a latex command but an environment
    ζ = subs(s, β.from, β.to)
    # Return relevant interpolated string based on case
    β.name == :DIV_OPEN && return "<div class=\"$(chop(ζ, head=2, tail=0))\">"
    β.name == :DIV_CLOSE && return "</div>"
    β.name == :CODE && return md2html(ζ)
    β.name == :ESCAPE && return ζ
    # Math block --> needs to call further processing to resolve possible latex
    β.name ∈ MD_MATHS_NAMES && return convert_mathblock(β, s, lxcontext.lxdefs)
    # default case: comment and co --> ignore block
    return ""
end


"""
    convert_mathblock(β, s, lxdefs)

Helper function for the math block case of `convert_block` taking the inside
of a math block, resolving any latex command in it and returning the correct
syntax that KaTeX can render.
"""
function convert_mathblock(β::Block, s::AbstractString, lxdefs::Vector{LxDef})
    β.name == :MATH_A && (pmath = (β.from+1, β.to-1, "\\(",  "\\)"))
    β.name == :MATH_B && (pmath = (β.from+2, β.to-2, "\$\$", "\$\$"))
    β.name == :MATH_C && (pmath = (β.from+2, β.to-2, "\\[",  "\\]"))
    β.name == :MATH_ALIGN && (pmath = (β.from+13, β.to-11,
                                "\$\$\\begin{aligned}", "\\end{aligned}\$\$"))
    β.name == :MATH_EQA   && (pmath = (β.from+16, β.to-14,
                                "\$\$\\begin{array}{c}", "\\end{array}\$\$"))
    # this is maths in a recursive parsing --> should not be
    # bracketed with KaTeX markers but just plugged in.
    β.name == :MATH_I && (pmath = (β.from+4, β.to-4, "", ""))

    # if none of the previous shortcut worked it's an unknown block
    !(@isdefined pmath) && error("Undefined math block name.")

    # otherwise we're good, convert the inside, decorate with KaTex and return
    inner = subs(s, pmath[1], pmath[2]) * EOS
    return pmath[3] * convert_md_math(inner, lxdefs) * pmath[4]
end
