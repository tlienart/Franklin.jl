"""
    stripp(s)

Convenience function to remove `<p>` and `</p>` added by the Base markdown to
html converter.
"""
function stripp(s::AbstractString)
    ts = ifelse(startswith(s, "<p>"), s[4:end], s)
    ts = ifelse(endswith(s, "</p>\n"), ts[1:end-5], ts)
    return ts
end

"""
    md2html(s, ismaths)

Convenience function to call the base markdown to html converter on "simple"
strings (i.e. strings that don't need to be further considered and don't
contain anything else than markdown tokens).
"""
function md2html(s::AbstractString, ismaths::Bool=false)
    isempty(s) && return s
    ismaths && return s
    pre = ifelse(s[1] == ' ', " ", "")
    post = ifelse(s[end] == '\n', "\n", "")
    return pre * stripp(Markdown.html(Markdown.parse(s))) * post
end


"""
    convert_md(mds, pre_lxdefs; isconfig, has_mddefs)

Convert a judoc markdown file into a judoc html.
"""
function convert_md(mds, pre_lxdefs=Vector{LxDef}();
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
    # figure out where the remaining blocks are.
    allblocks = get_md_allblocks(xblocks, lxdefs, lastindex(mds) - 1)
    # filter out trivial blocks
    allblocks = filter(β -> (mds[β.from:β.to] != "\n"), allblocks)

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

    # Form the string by converting each block given the latex context
    context = (mds, coms, lxdefs, bblocks)
    hstring = prod(convert_md__procblock(β, context...) for β ∈ allblocks)

    # Return the string + judoc variables if relevant
    return div_replace(hstring), (has_mddefs ? jd_vars : nothing)
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
   # default case, unlikely to happen
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
