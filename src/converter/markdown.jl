const JD_INSERT = "##JDINSERT##"
const PAT_JD_INSERT = Regex(JD_INSERT)
const LEN_JD_INSERT = length(JD_INSERT)

const JD_EQDICT = Dict{UInt, Int}()
const JD_EQDICT_COUNTER = hash("__JD_EQDICT_COUNTER__")

"""
    md2html(ss, stripp)

Convenience function to call the base markdown to html converter on "simple"
strings (i.e. strings that don't need to be further considered and don't
contain anything else than markdown tokens).
The boolean `stripp` indicates whether to remove the inserted `<p>` and `</p>`
by the base markdown processor, this is relevant for things that are parsed
within latex commands etc.
"""
function md2html(ss::AbstractString, stripp::Bool=false)
    isempty(ss) && return ss
    partial = Markdown.html(Markdown.parse(ss))
    stripp && return chop(partial, head=3, tail=5) # remove <p>...</p>\n
    return partial
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
    next_xblock = iszero(lenxb) ? BIG_INT : from(xblocks[1])

    # check when the next lxblock is, extra work because there may be lxdefs
    # passed through in *context* (i.e. that do not appear in mds) therefore
    # searcg first lxdef actually in mds (nothing if lxdefs is empty)
    first_lxd = findfirst(δ -> (from(δ) > 0), lxdefs)
    next_lxdef = isnothing(first_lxd) ? BIG_INT : from(lxdefs[first_lxd])

    # check which block is next
    xb_or_lx = (next_xblock < next_lxdef)
    next_idx = min(next_xblock, next_lxdef)

    head, xb_idx, lx_idx = 1, 1, first_lxd
    while (next_idx < BIG_INT) & (head < strlen)
        # check if there's anything before head and next block and push
        (head < next_idx) &&
            push!(pieces, subs(mds, head, prevind(mds, next_idx)))
        # check whether it's a xblock first or a newcommand first
        if xb_or_lx # it's a xblock --> push
            push!(pieces, JD_INSERT)
            head = nextind(mds, to(xblocks[xb_idx]))
            xb_idx += 1
            next_xblock = (xb_idx > lenxb) ? BIG_INT : from(xblocks[xb_idx])
        else # it's a newcommand --> no push
            head = nextind(mds, to(lxdefs[lx_idx]))
            lx_idx += 1
            next_lxdef = (lx_idx > lenlx) ? BIG_INT : from(lxdefs[lx_idx])
        end
        # check which block is next
        xb_or_lx = (next_xblock < next_lxdef)
        next_idx = min(next_xblock, next_lxdef)
    end
    # add final one if exists, chop EOS and adjust head
    (head <= strlen) && push!(pieces, subs(mds, head, strlen))
    return prod(pieces)
end


"""
    convert_md(mds, pre_lxdefs; isconfig, has_mddefs)

Convert a judoc markdown file into a judoc html.
"""
function convert_md(mds::String, pre_lxdefs=Vector{LxDef}();
                    isrecursive=false, isconfig=false, has_mddefs=true)

    # container for equation and id
    !isrecursive && (JD_EQDICT[JD_EQDICT_COUNTER] = 0)
    # Tokenize
    tokens = find_tokens(mds, MD_TOKENS, MD_1C_TOKENS)
    # Deactivate tokens within code blocks and other escape blocks
    tokens = deactivate_blocks(tokens, MD_EXTRACT)
    # Find brace blocks, do not deactivate tokens within them
    bblocks, tokens = find_md_ocblocks(tokens, :LXB,
                            :LXB_OPEN => :LXB_CLOSE, deactivate=false)
    # Find newcommands (latex definitions)
    lxdefs, tokens = find_md_lxdefs(tokens, bblocks)
    # if any lxdefs are given in the context, merge them. `pastdef!` specifies
    # that the definitions appear "earlier" by marking the `.from` at 0
    lprelx = length(pre_lxdefs)
    (lprelx > 0) && (lxdefs = cat(pastdef!.(pre_lxdefs), lxdefs, dims=1))
    # Find div blocks, deactivate tokens within them
    dblocks, tokens = find_md_ocblocks(tokens, :DIV,
                            :DIV_OPEN => :DIV_CLOSE)
    # Find other blocks to extract/escape (e.g.: code blocks)
    xblocks, tokens = find_md_xblocks(tokens)
    # Find lxcoms
    lxcoms, tokens = find_md_lxcoms(tokens, lxdefs, bblocks)
    # Merge the lxcoms and xblocks -> list of things to insert
    blocks2insert = merge_blocks(dblocks, xblocks, lxcoms)

    if has_mddefs
        # Process MD_DEF blocks
        mddefs = filter(β -> (β.name == :MD_DEF), xblocks)
        assignments = Vector{Pair{String, String}}(undef, length(mddefs))
        for (i, mdd) ∈ enumerate(mddefs)
            matched = match(MD_DEF_PAT, mdd.ss)
            isnothing(matched) && @warn "Found delimiters for an @def environment but I couldn't match it appropriately. Verify (will ignore for now)."
            vname, vdef = matched.captures[1:2]
            assignments[i] = (String(vname) => String(vdef))
        end
        # Assign as appropriate
        if isconfig
            isempty(assignments) || set_vars!(JD_GLOB_VARS, assignments)
            for lxd ∈ lxdefs
                JD_GLOB_LXDEFS[lxd.name] = lxd
            end
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
    hstring = convert_inter_html(inter_html, blocks2insert, lxcontext)

    # Return the string + judoc variables if relevant
    return hstring, (has_mddefs ? jd_vars : nothing)
end


"""
    convert_md_math(ms, lxdefs)

Same as `convert_md` except tailored for conversion of the inside of a
math block (no command definitions, restricted tokenisation to latex tokens).
"""
function convert_md_math(ms::String, lxdefs=Vector{LxDef}(), offset=0)
    # tokenize with restricted set
    tokens = find_tokens(ms, MD_TOKENS_LX, MD_1C_TOKENS_LX)
    bblocks, tokens = find_md_ocblocks(tokens, :LXB,
                            :LXB_OPEN => :LXB_CLOSE, deactivate=false)
    # in a math environment > pass a bool to indicate it
    lxcoms, tokens = find_md_lxcoms(tokens, lxdefs, bblocks, true, offset)
    # form the string (see `form_inter_md`, similar but fewer conditions)
    strlen = lastindex(ms) - 1
    pieces = Vector{AbstractString}()
    lenlxc = length(lxcoms)
    next_lxcom = iszero(lenlxc) ? BIG_INT : from(lxcoms[1])
    head, lxcom_idx = 1, 1
    while (next_lxcom < BIG_INT) & (head < strlen)
        (head < next_lxcom) && push!(pieces, subs(ms, head, next_lxcom-1))
        push!(pieces, resolve_lxcom(lxcoms[lxcom_idx], lxdefs, true))
        head = nextind(ms, to(lxcoms[lxcom_idx]))
        lxcom_idx += 1
        next_lxcom = (lxcom_idx > lenlxc) ? BIG_INT : from(lxcoms[lxcom_idx])
    end
    (head <= strlen) && push!(pieces, chop(ms, head=prevind(ms, head), tail=1))
    return prod(pieces)
end


"""
    convert_inter_md(intermd, refmd, xblocks, coms, lxdefs, bblocks)

Take a partial markdown string with the `JD_INSERT` marker and plug in the
appropriately processed block.
"""
function convert_inter_html(interhtml::AbstractString,
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
        push!(pieces, convert_block(blocks2insert[i], lxcontext))
    end
    # store whatever is after the last JD_INSERT if anything
    (head <= strlen) && push!(pieces, subs(interhtml, head, strlen))
    # return the full string
    return prod(pieces)
end


"""
    convert_block(β, lxc)

Helper function for `convert_inter_html` that processes an extracted block
given a latex context `lxc` and return the processed html that needs to be
plugged in the final html.
"""
function convert_block(β::B, lxc::LxContext) where B <: AbstractBlock
    # Return relevant interpolated string based on case
    βn = β.name
    βn == :CODE_INLINE && return md2html(β.ss, true)
    βn == :CODE_BLOCK  && return md2html(β.ss)
    βn == :ESCAPE      && return chop(β.ss, head=3, tail=3)
    # Math block --> needs to call further processing to resolve possible latex
    βn ∈ MD_MATHS_NAMES && return convert_mathblock(β, lxc.lxdefs)
    # Div block --> need to process the block as a sub-element
    if βn == :DIV
        ct, _ = convert_md(content(β) * EOS, lxc.lxdefs;
                        isrecursive=true, has_mddefs=false)
        d1 = "<div class=\"$(chop(β.ocpair.first.ss, head=2, tail=0))\">"
        d2 = "</div>\n"
        return d1 * ct * d2
    end
    # default case: comment and co --> ignore block
    return ""
end
convert_block(β::LxCom, lxc::LxContext) = resolve_lxcom(β, lxc.lxdefs)


"""
    convert_mathblock(β, s, lxdefs)

Helper function for the math block case of `convert_block` taking the inside
of a math block, resolving any latex command in it and returning the correct
syntax that KaTeX can render.
"""
function convert_mathblock(β::Block, lxdefs::Vector{LxDef})
    βn = β.name
    # pm[1] and pm[2] indicate the number of characters to remove on left and
    # right. So for example, a MATH_B is \$\$...\$\$ so two characters (\$\$)
    # to remove on each side.
    # pm[3] and pm[4] indicate what we have to write for KaTeX instead.
    # pm[5] indicates whether it has a number or not
    βn == :MATH_A     && (pm = ( 1,  1, "\\(",  "\\)"))
    βn == :MATH_B     && (pm = ( 2,  2, "\$\$", "\$\$"))
    βn == :MATH_C     && (pm = ( 2,  2, "\\[",  "\\]"))
    βn == :MATH_ALIGN && (pm = (13, 11, "\$\$\\begin{aligned}", "\\end{aligned}\$\$"))
    βn == :MATH_EQA   && (pm = (16, 14, "\$\$\\begin{array}{c}", "\\end{array}\$\$"))
    # this is maths in a recursive parsing --> should not be
    # bracketed with KaTeX markers but just plugged in.
    βn == :MATH_I && (pm = (4, 4, "", ""))

    # if none of the previous shortcut worked it's an unknown block
    !(@isdefined pm) && error("Undefined math block name.")

    # otherwise we're good, convert the inside, decorate with KaTex and return
    # also if the math block is a "display" one (with a number)
    inner = chop(β.ss, head=pm[1], tail=pm[2])
    anchor = ""
    if βn ∉ [:MATH_A, :MATH_I]
        # NOTE: in the future if allow equation tags, then will need an `if`
        # here and only increment if there's no tag. For now just use numbers.
        JD_EQDICT[JD_EQDICT_COUNTER] += 1
        matched = match(r"\\label{(.*?)}", inner)
        if !isnothing(matched)
            name = hash(matched.captures[1])
            anchor = "<a name=\"$name\"></a>"
            JD_EQDICT[name] = JD_EQDICT[JD_EQDICT_COUNTER]
            inner = replace(inner, r"\\label{.*?}" => "")
        end
    end
    inner *= EOS
    return anchor * pm[3] * convert_md_math(inner, lxdefs, from(β)) * pm[4]
end
