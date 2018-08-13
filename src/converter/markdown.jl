function convert_md(mds, pre_lxdefs=Vector{LxDef}();
                     isconfig=false, has_mddefs=true)
    # Tokenize
    tokens = find_tokens(mds, MD_TOKENS, MD_1C_TOKENS)
    # Get rid of tokens within code blocks
    tokens = deactivate_md_xblocks(mds)
    # Find brace blocks
    bblocks, tokens = find_md_bblocks(tokens)
    # Find newcommands (latex definitions)
    lxdefs, tokens = find_md_lxdefs(st, tokens, bblocks)
    # Find blocks to extract
    xblocks, tokens = JuDoc.find_md_xblocks(tokens)
    # Kill trivial tokens that may remain
    tokens = filter(τ -> (τ.name != :LINE_RETURN), tokens)
    # figure out where the remaining blocks are.
    allblocks = JuDoc.get_allblocks(xblocks, lxdefs, endof(st) - 1)
    # filter out trivial blocks
    allblocks = filter(β -> (st[β.from:β.to] != "\n"), allblocks)

    # if any lxdefs are given in the context, merge them. `pastdef!` specifies
    # that the definitions appear "earlier" by marking the `.from` at 0
    lprelx = length(pre_lxdefs)
    (lprelx > 0) && (lxdefs = cat(1, pastdef!.(pre_lxdefs), lxdefs))

    # find commands
    coms = filter(τ -> (τ.name == :LX_COMMAND), tokens)

    if has_mddefs
        # Process MD_DEF blocks
        mdd = filter(b -> (b.name == :MD_DEF), allblocks)
        assignments = Vector{Pair{String, String}}(length(mdd))
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

    # Form the string by converting each block given the latex context
    context = (mds, coms, lxdefs, bblocks)
    hstring = prod(convert_md__procblock(β, context...) for β ∈ allblocks)

    # Return the string + judoc variables if relevant
    return hstring, (has_mddefs ? jd_vars : nothing)
end


"""
    convert_md__procblock(β, mds, lxdefs, bblocks)

Helper function to process an individual block given its context and convert it
to the appropriate html string.
"""
function convert_md__procblock(β::Block, mds, coms, lxdefs, bblocks)
    #=
    REMAIN BLOCKS: (most common block)
    These are interstitial blocks (typically text) that may contain
    user-defined latex that needs to be resolved as well as basic markdown
    that will be processed by the default html converter.
    =#
    if β.name == :REMAIN
        tempstring = resolve_latex(mds, β.from, β.to, false,
                                   coms, lxdefs, bblocks)
        ts = html(Markdown.parse(tempstring))
        #= HACK: the base markdown converter adds <p> ... </p> around what
        it converts. Since we convert by blocks, this adds too many of
        those. This should be fine most of the time but there may be
        edge cases that will need to be processed further. =#
        tts = startswith(ts, "<p>") ? ts[4:end] : ts
        tts = endswith(ts, "</p>\n") ? tts[1:end-5] : tts
        return tts
    #=
    ESCAPE BLOCKS:
    These blocks are just plugged "as is", removing the '~~~' that
    surround them.
    =#
    elseif β.name == :ESCAPE
        return mds[β.from+3:β.to-3]
    #=
    CODE BLOCKS:
    These blocks are just given to the html engine to be parsed, they are
    parsed separately so that any symbols that they may contain does not
    trigger further processing.
    =#
    elseif β.name ∈ [:CODE_SINGLE, :CODE]
        return html(Markdown.parse(mds[β.from:β.to]))
    #=
    MATH BLOCKS:
    These blocks may contain user-defined latex commands that need to be
    processed. Then, depending on the case, they are plugged in with their
    appropriate KaTeX markers.
    =#
    elseif β.name ∈ MD_MATHS_NAMES
        pmath = convert_md__procmath(β)
        tmpst = resolve_latex(mds, pmath[1], pmath[2], true, coms,
                             lxdefs, bblocks)
        # add the relevant KaTeX brackets
        return pmath[3] * tmpst * pmath[4]
   else
       return ""
   end
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
