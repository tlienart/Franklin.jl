"""
    stripp(s)

Convenience function to remove `<p>` and `</p>` added by the Base markdown to
html converter.
"""
function stripp(s::AbstractString)
    ts = ifelse(startswith(s, "<p>"), chop(s, 4, tail=0), s)
    ts = ifelse(endswith(s, "</p>\n"), chop(s, tail=5), ts)
    return ts
end


"""
    md2html(s, ismaths)

Convenience function to call the base markdown to html converter on "simple"
strings (i.e. strings that don't need to be further considered and don't
contain anything else than markdown tokens).
Note: it may get fed with a `SubString` whence the use of `AbstractString`.
"""
function md2html(s::AbstractString, ismaths::Bool=false)
    isempty(s) && return s
    ismaths && return s
    pre = ifelse(startswith(s, ' '), " ", "")
    post = ifelse(endswith(s, '\n'), "\n", "")
    return pre * stripp(Markdown.html(Markdown.parse(s))) * post
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

    strlen = lastindex(mds) - 1
    pieces = Vector{Union{String, SubString}}()

    lenxb = length(xblocks)
    lenlx = length(lxdefs)

    next_xblock = iszero(lenxb) ? BIG_INT : xblocks[1].from
    next_lxdef = iszero(lenlx) ? BIG_INT : lxdefs[1].from

    # check which block is next
    xb_or_lx = (next_xblock < next_lxdef)
    next_idx = min(next_xblock, next_lxdef)

    head, xb_idx, lx_idx = 1, 1, 1
    while (next_idx < BIG_INT) & (head < strlen)
        # check if there's anything before head and next block and push
        (head < next_idx) && push!(pieces, SubString(mds, head, next_idx-1))

        if xb_or_lx # next block is xblock
            push!(pieces, JD_INSERT)
            head = xblocks[xb_idx].to + 1
            xb_idx += 1
            next_xblock = (xb_idx > lenxb) ? BIG_INT : xblocks[xb_idx].from
        else # next block is newcommand, no push
            head = lxdefs[lx_idx].to + 1
            lx_idx += 1
            next_lxdef = (lx_idx > lenlx) ? BIG_INT : lxdefs[lx_idx].from
        end

        # check which block is next
        xb_or_lx = (next_xblock < next_lxdef)
        next_idx = min(next_xblock, next_lxdef)
    end
    # add final one if exists
    (head < strlen) && push!(pieces, chop(mds, head=head, tail=1))
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

    # >>HACK
    # # figure out where the remaining blocks are.
    # allblocks = get_md_allblocks(xblocks, lxdefs, lastindex(mds) - 1)
    # # filter out trivial blocks
    # allblocks = filter(β -> (mds[β.from:β.to] != "\n"), allblocks)
    # <<HACK

    # if any lxdefs are given in the context, merge them. `pastdef!` specifies
    # that the definitions appear "earlier" by marking the `.from` at 0
    lprelx = length(pre_lxdefs)
    (lprelx > 0) && (lxdefs = cat(pastdef!.(pre_lxdefs), lxdefs, dims=1))

    # find commands
    coms = filter(τ -> (τ.name == :LX_COMMAND), tokens)

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

    inter_md = form_interm_md(mds, xblocks, lxdefs)
    interm_html = md2html(inter_md)

    # >>HACK
    # # Form the string by converting each block given the latex context
    # context = (mds, coms, lxdefs, bblocks)
    # hstring = prod(convert_md__procblock(β, context...) for β ∈ allblocks)
    # <<HACK

    # Return the string + judoc variables if relevant
    return div_replace(hstring), (has_mddefs ? jd_vars : nothing)
end


"""
    insert_proc_xblocks(pmd, xblocks, lxdefs)

Take a partial markdown string with the `JD_INSERT` marker and plug in the --
appropriately processed -- block.
"""
function insert_proc_xblocks(pmd::String, xblocks::Vector{Block},
                             lxdefs::Vector{LxDef}, bblocks::Vector{Block})

    allmatches = collect(eachmatch(PAT_JD_INSERT, pmd))
    pieces = Vector{Union{SubString, String}}()
    strlen = lastindex(pmd)

    head = 1
    for (i, m) ∈ enumerate(allmatches)
        (head < m.offset) && push!(pieces, SubString(pmd, head, m.offset-1))
        head = m.offset + LEN_JD_INSERT
        # push! the resolved block
        push!(pieces, process_xblock(xblocks[i], lxdefs, bblocks))
    end
    (head < strlen) && push!(pieces, head => strlen)
end


"""
"""
function process_xblock(β::Block, lxdefs::Vector{LxDef},
                        bblocks::Vector{Block})

    # TODO
    # β.name == DIV_OPEN
    # β.name == DIV_CLOSE
    # β.name == CODE_SINGLE, CODE ==> just md2html
    # β.name == ESCAPE ==> no processing
    # β.name ∈ MD_MATHS_NAMES

    # default (& COMMENT): ""
end


"""
    convert_md__procblock(β, mds, lxdefs, bblocks)

Helper function to process an individual block given its context and convert it
to the appropriate html string.
"""
function convert_md__procblock(β::Block, mds::String, coms, lxdefs, bblocks)
    #=
    REMAIN BLOCKS: (most common block)
    These are interstitial blocks (typically text) that may contain
    user-defined latex that needs to be resolved as well as basic markdown
    that will be processed by the default html converter.
    =#
    β.name == :REMAIN && return resolve_latex(mds, β.from, β.to, false,
                                              coms, lxdefs, bblocks)
    #=
    ESCAPE BLOCKS:
    These blocks are just plugged "as is", removing the '~~~' that
    surround them.
    =#
    β.name == :ESCAPE && return mds[β.from+3:β.to-3]
    #=
    CODE BLOCKS:
    These blocks are just given to the html engine to be parsed, they are
    parsed separately so that any symbols that they may contain does not
    trigger further processing.
    =#
    β.name ∈ [:CODE_SINGLE, :CODE] && return md2html(mds[β.from:β.to])
    #=
    MATH BLOCKS:
    These blocks may contain user-defined latex commands that need to be
    processed. Then, depending on the case, they are plugged in with their
    appropriate KaTeX markers.
    =#
    if β.name ∈ MD_MATHS_NAMES
        pmath = convert_md__procmath(β)
        tmpst = resolve_latex(mds, pmath[1], pmath[2], true, coms,
                              lxdefs, bblocks)
        # add the relevant KaTeX brackets
        return pmath[3] * tmpst * pmath[4]
   end
   # default case: comment and co
   return ""
end


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
