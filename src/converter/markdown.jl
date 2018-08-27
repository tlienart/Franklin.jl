# """
#     stripp(s)
#
# Convenience function to remove `<p>` and `</p>` added by the Base markdown to
# html converter.
# """
# function stripp(s::AbstractString)
#     ts = ifelse(startswith(s, "<p>"), chop(s, 4, tail=0), s)
#     ts = ifelse(endswith(s, "</p>\n"), chop(s, tail=5), ts)
#     return ts
# end
"""
    md2html(s, ismaths)

Convenience function to call the base markdown to html converter on "simple"
strings (i.e. strings that don't need to be further considered and don't
contain anything else than markdown tokens).
Note: it may get fed with a `SubString` whence the use of `AbstractString`.
"""
function md2html(s::AbstractString)
    isempty(s) && return s
    return Markdown.html(Markdown.parse(s))
end


const JD_INSERT = "##JDINSERT##"
const PAT_JD_INSERT = Regex(JD_INSERT)
const LEN_JD_INSERT = length(JD_INSERT)

"""
    form_interm_md(mds, xblocks, lxdefs)

Form an intermediate MD file where special blocks are replaced by a marker
(`JD_INSERT`) indicating that a piece will need to be plugged in there later.
"""
function form_interm_md(mds::String, xblocks::Vector{Block},
                        lxdefs::Vector{LxDef})

    strlen = lastindex(mds) - 1 # final character is the EOS character
    pieces = Vector{AbstractString}()

    lenxb = length(xblocks)
    lenlx = length(lxdefs)

    # check when the next xblock is
    next_xblock = iszero(lenxb) ? BIG_INT : xblocks[1].from

    # check when the next lxblock is, extra work because there may be lxdefs
    # passed through in *context* (i.e. that do not appear in mds) therefore
    # searcg first lxdef actually in mds (nothing if lxdefs is empty)
    first_lxd = findfirst(δ -> (δ.from > 0), lxdefs)
    next_lxdef = (first_lxd == nothing) ? BIG_INT : lxdefs[first_lxd].from

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
function convert_md(mds::String, pre_lxdefs=Vector{LxDef}();
                    isconfig=false, has_mddefs=true)
    # Tokenize
    tokens = find_tokens(mds, MD_TOKENS, MD_1C_TOKENS)
    # Deactivate tokens within code blocks
    tokens = deactivate_xblocks(tokens, MD_EXTRACT)
    # Find brace blocks
    bblocks, tokens = find_md_bblocks(tokens)
    # Find newcommands (latex definitions)
    lxdefs, tokens = find_md_lxdefs(mds, tokens, bblocks)
    # Find blocks to extract
    xblocks, tokens = find_md_xblocks(tokens)
    # Kill trivial tokens that may remain
    tokens = filter(τ -> (τ.name != :LINE_RETURN), tokens)

    # if any lxdefs are given in the context, merge them. `pastdef!` specifies
    # that the definitions appear "earlier" by marking the `.from` at 0
    lprelx = length(pre_lxdefs)
    (lprelx > 0) && (lxdefs = cat(pastdef!.(pre_lxdefs), lxdefs, dims=1))

    # find commands
    lxcoms = filter(τ -> (τ.name == :LX_COMMAND), tokens)

    if has_mddefs
        # Process MD_DEF blocks
        mdd = filter(b -> (b.name == :MD_DEF), allblocks)
        assignments = Vector{Pair{String, String}}(undef, length(mdd))
        for i ∈ eachindex(mdd)
            m = match(MD_DEF_PAT, mds[mdd[i].from:mdd[i].to])
            m == nothing && warn("Found delimiters for an @def environment but I couldn't match it, verify $(mds[mdd[i].from:mdd[i].to]). Ignoring.")
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
    inter_md = form_interm_md(mds, xblocks, lxdefs)
    # plug resolved blocks in partial html to form the final html
    lxcontext = LxContext(lxcoms, lxdefs, bblocks)
    hstring = insert_proc_xblocks(md2html(inter_md), mds, xblocks, lxcontext)
    # Return the string + judoc variables if relevant
    return hstring, (has_mddefs ? jd_vars : nothing)
end


"""
    insert_proc_xblocks(pmd, mds, xblocks, coms, lxdefs, bblocks)

Take a partial markdown string with the `JD_INSERT` marker and plug in the --
appropriately processed -- block.
"""
function insert_proc_xblocks(phs::String, mds::String, xblocks::Vector{Block},
                             lxcontext::LxContext)

    allmatches = collect(eachmatch(PAT_JD_INSERT, phs))
    pieces = Vector{AbstractString}()
    strlen = lastindex(phs)

    head = 1
    for (i, m) ∈ enumerate(allmatches)
        (head < m.offset) && push!(pieces, subs(phs, head, m.offset-1))
        head = m.offset + LEN_JD_INSERT
        # push! the resolved block
        push!(pieces, process_xblock(xblocks[i], mds, lxcontext))
    end
    (head < strlen) && push!(pieces, subs(phs, head, strlen))
    return prod(pieces)
end


# TODO TODO TODO complete doc
function process_xblock(β::Block, s::String, lxcontext::LxContext)

    ζ = subs(s, β.from, β.to)
    # Return relevant interpolated string based on case
    β.name == DIV_OPEN && return "<div class=\"$(chop(ζ, head=2, tail=0))\">"
    β.name == DIV_CLOSE && return "</div>"
    β.name == :CODE && return md2html(ζ)
    β.name == :ESCAPE && return ζ
    if β.name ∈ MD_MATHS_NAMES
        pmath = convert_md__procmath(β)
        rlx = resolve_latex(mds, pmath[1], pmath[2], true, lxcontext)
        return pmath[3] * rlx * pmath[4]
    end
    # default case: comment and co --> ignore block
    return ""
end


function process_xblock(β::LxCom, s::String, lxcontext::LxContext)
end


# """
#     convert_md__procblock(β, mds, lxdefs, bblocks)
#
# Helper function to process an individual block given its context and convert it
# to the appropriate html string.
# """
# function convert_md__procblock(β::Block, mds::String, coms, lxdefs, bblocks)
#     #=
#     REMAIN BLOCKS: (most common block)
#     These are interstitial blocks (typically text) that may contain
#     user-defined latex that needs to be resolved as well as basic markdown
#     that will be processed by the default html converter.
#     =#
#     β.name == :REMAIN && return resolve_latex(mds, β.from, β.to, false,
#                                               coms, lxdefs, bblocks)
#     #=
#     ESCAPE BLOCKS:
#     These blocks are just plugged "as is", removing the '~~~' that
#     surround them.
#     =#
#     β.name == :ESCAPE && return mds[β.from+3:β.to-3]
#     #=
#     CODE BLOCKS:
#     These blocks are just given to the html engine to be parsed, they are
#     parsed separately so that any symbols that they may contain does not
#     trigger further processing.
#     =#
#     β.name ∈ [:CODE_SINGLE, :CODE] && return md2html(mds[β.from:β.to])
#     #=
#     MATH BLOCKS:
#     These blocks may contain user-defined latex commands that need to be
#     processed. Then, depending on the case, they are plugged in with their
#     appropriate KaTeX markers.
#     =#
#     if β.name ∈ MD_MATHS_NAMES
#         pmath = convert_md__procmath(β)
#         tmpst = resolve_latex(mds, pmath[1], pmath[2], true, coms,
#                               lxdefs, bblocks)
#         # add the relevant KaTeX brackets
#         return pmath[3] * tmpst * pmath[4]
#    end
#    # default case: comment and co
#    return ""
# end


"""
    convert_md__procmath(β)

Helper function to process an individual math block.
"""
function convert_md__procmath(β::Block)
   β.name == :MATH_A && return (β.from+1, β.to-1, "\\(",  "\\)")
   β.name == :MATH_B && return (β.from+2, β.to-2, "\$\$", "\$\$")
   β.name == :MATH_C && return (β.from+2, β.to-2, "\\[",  "\\]")

   β.name == :MATH_ALIGN && return (β.from+13, β.to-11,
                                 "\$\$\\begin{aligned}", "\\end{aligned}\$\$")
   β.name == :MATH_EQA   && return (β.from+16, β.to-14,
                                 "\$\$\\begin{array}{c}", "\\end{array}\$\$")

   # this is maths in a recursive parsing --> should not be
   # bracketed with KaTeX markers but just plugged in.
   β.name == :MATH_I && return (β.from+4, β.to-4, "", "")

   # will not happen
   error("Undefined math block name.")
end
