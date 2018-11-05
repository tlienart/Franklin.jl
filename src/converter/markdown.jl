"""
    JD_INSERT

String that is plugged as a placeholder of blocks that need further processing.
The spaces allow to handle overzealous inclusion of `<p>...</p>` from the base
Markdown to HTML conversion.
"""
const JD_INSERT     = " ##JDINSERT## "
const JD_INSERT_    = strip(JD_INSERT)
const JD_INSERT_PAT = Regex(JD_INSERT_)
const JD_INSERT_LEN = length(JD_INSERT_)

"""
    md2html(ss, stripp)

Convenience function to call the base markdown to html converter on "simple"
strings (i.e. strings that don't need to be further considered and don't
contain anything else than markdown tokens).
The boolean `stripp` indicates whether to remove the inserted `<p>` and `</p>`
by the base markdown processor, this is relevant for things that are parsed
within latex commands etc.
"""
function md2html(ss::AbstractString,
                 stripp = false)

    isempty(ss) && return ss
    # Use the base Markdown -> Html converter
    partial = Markdown.html(Markdown.parse(ss))

    # In some cases, base converter adds <p>...</p>\n which we might not want
    stripp && return chop(partial, head=3, tail=5)

    return partial
end


"""
    form_inter_md(mds, blocks, lxdefs)

Form an intermediate MD file where special blocks are replaced by a marker
(`JD_INSERT`) indicating that a piece will need to be plugged in there later.
"""
function form_inter_md(mds::AbstractString,
                       blocks::Vector{<:AbstractBlock},
                       lxdefs::Vector{LxDef})

    # final character is the EOS character
    strlen  = prevind(mds, lastindex(mds))
    pieces  = Vector{AbstractString}()
    # keep track of the matching blocks for each insert
    mblocks = Vector{AbstractBlock}()

    len_b   = length(blocks)
    len_lxd = length(lxdefs)

    # check when the next block is
    next_b = iszero(len_b) ? BIG_INT : from(blocks[1])

    # check when the next lxblock is, extra work because there may be lxdefs
    # passed through in *context* (i.e. that do not appear in mds) therefore
    # search first lxdef actually in mds (nothing if lxdefs is empty)
    first_lxd = findfirst(δ -> (from(δ) > 0), lxdefs)
    next_lxd  = isnothing(first_lxd) ? BIG_INT : from(lxdefs[first_lxd])

    # check what's next: a block or a lxdef
    b_or_lxd = (next_b < next_lxd)
    nxtidx = min(next_b, next_lxd)

    # keep track of a few counters
    head, b_idx, lxd_idx = 1, 1, first_lxd

    while (nxtidx < BIG_INT) & (head < strlen)
        # check if there's anything before head and next block and push it
        (head < nxtidx) && push!(pieces, subs(mds, head, prevind(mds, nxtidx)))

        # check whether it's a block first or a newcommand first
        if b_or_lxd # it's a block, check if should be pushed
            β = blocks[b_idx]
            # check whether the block should be skipped
            if isa(β, OCBlock) && β.name ∈ MD_OCB_IGNORE
                head = nextind(mds, to(β))
            else # push
                push!(pieces, JD_INSERT)
                push!(mblocks, β)
                head = nextind(mds, to(blocks[b_idx]))
            end
            b_idx += 1
            next_b = from_ifsmaller(blocks, b_idx, len_b)

        else # newcommand or ignore --> skip, increase counters, move head
            head     = nextind(mds, to(lxdefs[lxd_idx]))
            lxd_idx += 1
            next_lxd = from_ifsmaller(lxdefs, lxd_idx, len_lxd)
        end
        # check which block is next
        b_or_lxd = (next_b < next_lxd)
        nxtidx = min(next_b, next_lxd)
    end
    # add whatever is after the last block
    (head <= strlen) && push!(pieces, subs(mds, head, strlen))

    # combine everything and return
    return prod(pieces), mblocks
end


"""
    convert_md(mds, pre_lxdefs; isrecursive, isconfig, has_mddefs)

Convert a judoc markdown file read as `mds` into a judoc html.
- `pre_lxdefs` is a vector of `LxDef` that are already available.
- `isrecursive` indicates whether the call is the parent call or a child call
- `isconfig` indicates whether the file to convert is the configuration file
- `has_mddefs` whether to look for definitions of page variables or not
"""
function convert_md(mds::String,
                    pre_lxdefs  = Vector{LxDef}();
                    isrecursive = false,
                    isconfig    = false,
                    has_mddefs  = true)

    if !isrecursive
        def_LOC_VARS()           # page-specific variables
        def_JD_LOC_EQDICT()      # page-specific equation dict (hrefs)
        def_JD_LOC_BIBREFDICT()  # page-specific reference dict (hrefs)
    end

    # Tokenize & deactivate the tokens
    tokens = find_tokens(mds, MD_TOKENS, MD_1C_TOKENS)

    # Find all open-close blocks
    blocks, tokens = find_md_ocblocks(tokens)

    # Find newcommands (latex definitions), update active blocks/braces
    lxdefs, tokens, braces, blocks = find_lxdefs(tokens, blocks)
    # if any lxdefs are given in the context, merge them. `pastdef!` specifies
    # that the definitions appear "earlier" by marking the `.from` at 0
    lprelx = length(pre_lxdefs)
    (lprelx > 0) && (lxdefs = cat(pastdef!.(pre_lxdefs), lxdefs, dims=1))

    # Find lxcoms
    lxcoms, _ = find_md_lxcoms(tokens, lxdefs, braces)

    jd_vars = nothing
    if has_mddefs
        # Process MD_DEF blocks
        mddefs = filter(β -> (β.name == :MD_DEF), blocks)
        assignments = Vector{Pair{String, String}}(undef, length(mddefs))
        for (i, mdd) ∈ enumerate(mddefs)
            matched = match(MD_DEF_PAT, mdd.ss)
            isnothing(matched) && (@warn "Found delimiters for an @def environment but I couldn't match it appropriately. Verify (will ignore for now)."; continue)
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

    # Merge all the blocks that will need further processing before insertion
    blocks2insert = merge_blocks(lxcoms, deactivate_divs(blocks))

    # form intermediate markdown + html
    inter_md, mblocks = form_inter_md(mds, blocks2insert, lxdefs)
    inter_html = md2html(inter_md, isrecursive)

    # plug resolved blocks in partial html to form the final html
    lxcontext = LxContext(lxcoms, lxdefs, braces)
    hstring   = convert_inter_html(inter_html, mblocks, lxcontext)

    # Return the string + judoc variables if relevant
    return hstring, jd_vars
end


"""
    convert_md_math(ms, lxdefs, offset)

Same as `convert_md` except tailored for conversion of the inside of a
math block (no command definitions, restricted tokenisation to latex tokens).
The offset keeps track of where the math block was, which is useful to check
whether any of the latex command used in the block have not yet been defined.
"""
function convert_md_math(ms::String,
                         lxdefs = Vector{LxDef}(),
                         offset = 0)

    # tokenize with restricted set, find braces
    tokens = find_tokens(ms, MD_TOKENS_LX, MD_1C_TOKENS_LX)
    blocks, tokens = find_md_ocblocks(tokens, inmath=true)
    braces = filter(β -> β.name == :LXB, blocks) # should be all of them

    # in a math environment -> pass a bool to indicate it as well as offset
    lxcoms, _ = find_md_lxcoms(tokens, lxdefs,  braces, offset; inmath=true)

    # form the string (see `form_inter_md`, similar but fewer conditions)
    strlen   = prevind(ms, lastindex(ms))
    pieces   = Vector{AbstractString}()
    len_lxc  = length(lxcoms)
    next_lxc = iszero(len_lxc) ? BIG_INT : from(lxcoms[1])
    head, lxc_idx = 1, 1
    while (next_lxc < BIG_INT) & (head < strlen)
        # add anything that may occur before the first command
        (head < next_lxc) &&
            push!(pieces, subs(ms, head, prevind(ms, next_lxc)))
        # add the first command after resolving, bool to indicate that inmath
        push!(pieces, resolve_lxcom(lxcoms[lxc_idx], lxdefs, inmath=true))
        # move the head
        head     = nextind(ms, to(lxcoms[lxc_idx]))
        lxc_idx += 1
        next_lxc = from_ifsmaller(lxcoms, lxc_idx, len_lxc)
    end
    # add anything after the last command
    (head <= strlen) && push!(pieces, chop(ms, head=prevind(ms, head), tail=1))

    # combine everything
    return prod(pieces)
end


"""
    convert_inter_html(ihtml, blocks, lxcontext)

Take a partial markdown string with the `JD_INSERT` marker and plug in the
appropriately processed block.
"""
function convert_inter_html(ihtml::AbstractString,
                            blocks::Vector{<:AbstractBlock},
                            lxcontext::LxContext)

    # Find the JD_INSERT indicators
    allmatches = collect(eachmatch(JD_INSERT_PAT, ihtml))
    pieces = Vector{AbstractString}()
    strlen = lastindex(ihtml)

    # construct the pieces of the final html in order, gradually processing
    # the blocks to insert.
    head = 1
    for (i, m) ∈ enumerate(allmatches)
        # two cases can happen based on whitespaces around an insertion that we
        # want to get rid of, potentially both happen simultaneously.
        # 1. <p>##JDINSERT##...
        # 2. ...##JDINSERT##</p>
        # exceptions,
        # - list items introduce <li><p> and </p>\n</li> which shouldn't remove
        # - end of doc introduces </p>(\n?) which should not be removed
        δ1, δ2 = 0, 0 # keep track of the offset at the front / back
        # => case 1
        c10 = prevind(ihtml, m.offset, 7) # *li><p>
        c1a = prevind(ihtml, m.offset, 3) # *p>
        c1b = prevind(ihtml, m.offset)    # <p*

        hasli1 = (c10 > 0) && ihtml[c10:c1b] == "<li><p>"
        !(hasli1) && (c1a > 0) && ihtml[c1a:c1b] == "<p>" && (δ1 = 3)

        # => case 2
        iend = m.offset + JD_INSERT_LEN
        c2a  = nextind(ihtml, iend)
        c2b  = nextind(ihtml, iend, 4)  # </p*
        c20  = nextind(ihtml, iend, 10) # </p>\n</li*

        hasli2 = (c20 ≤ strlen) && ihtml[c2a:c20] == "</p>\n</li>"
        !(hasli2) && (c2b ≤ strlen - 4) && ihtml[c2a:c2b] == "</p>" && (δ2 = 4)

        # push whatever is at the front, skip the extra space if still present
        δ1 = ifelse(iszero(δ1) && !hasli1, 1, δ1)
        prev = (m.offset - δ1 > 0) ? prevind(ihtml, m.offset - δ1) : 0
        (head ≤ prev) && push!(pieces, subs(ihtml, head:prev))
        # move head appropriately
        head = iend + δ2 + 1
        # store the resolved block
        push!(pieces, convert_block(blocks[i], lxcontext))
    end
    # store whatever is after the last JD_INSERT if anything
    (head ≤ strlen) && push!(pieces, subs(ihtml, head:strlen))

    # return the full string
    return prod(pieces)
end


"""
    convert_block(β, lxc)

Helper function for `convert_inter_html` that processes an extracted block
given a latex context `lxc` and returns the processed html that needs to be
plugged in the final html.
"""
function convert_block(β::B, lxcontext::LxContext) where B <: AbstractBlock

    # Return relevant interpolated string based on case
    βn = β.name
    βn == :CODE_INLINE  && return md2html(β.ss, true)
    βn == :CODE_BLOCK_L && return md2html(β.ss)
    βn == :CODE_BLOCK   && return md2html(β.ss)
    βn == :ESCAPE       && return chop(β.ss, head=3, tail=3)

    # Math block --> needs to call further processing to resolve possible latex
    βn ∈ MD_MATH_NAMES && return convert_mathblock(β, lxcontext.lxdefs)

    # Div block --> need to process the block as a sub-element
    if βn == :DIV
        ct, _ = convert_md(content(β) * EOS, lxcontext.lxdefs;
                           isrecursive=true, has_mddefs=false)
        name = chop(otok(β).ss, head=2, tail=0)
        return html_div(name, ct)
    end

    # default case --> ignore block (should not happen)
    return ""
end
convert_block(β::LxCom, λ::LxContext) = resolve_lxcom(β, λ.lxdefs)


"""
    JD_MBLOCKS_PM

Dictionary to keep track of how math blocks are fenced in standard LaTeX and
how these fences need to be adapted for compatibility with KaTeX.
Each tuple contains the number of characters to chop off the front and the back
of the maths expression (fences) as well as the KaTeX-compatible replacement.
For instance, `\$ ... \$` will become `\\( ... \\)` chopping off 1 character at
the front and the back (`\$` sign).
"""
const JD_MBLOCKS_PM = Dict{Symbol, Tuple{Int, Int, String, String}}(
    :MATH_A     => ( 1,  1, "\\(",  "\\)"),
    :MATH_B     => ( 2,  2, "\$\$", "\$\$"),
    :MATH_C     => ( 2,  2, "\\[",  "\\]"),
    :MATH_ALIGN => (13, 11, "\$\$\\begin{aligned}", "\\end{aligned}\$\$"),
    :MATH_EQA   => (16, 14, "\$\$\\begin{array}{c}", "\\end{array}\$\$"),
    :MATH_I     => ( 4,  4, "", "")
)


"""
    convert_mathblock(β, s, lxdefs)

Helper function for the math block case of `convert_block` taking the inside
of a math block, resolving any latex command in it and returning the correct
syntax that KaTeX can render.
"""
function convert_mathblock(β::OCBlock, lxdefs::Vector{LxDef})

    # try to find the block out of `JD_MBLOCKS_PM`, if not found, error
    pm = get(JD_MBLOCKS_PM, β.name) do
        error("Unrecognised math block name.")
    end

    # convert the inside, decorate with KaTex and return, also act if
    # if the math block is a "display" one (with a number)
    inner  = chop(β.ss, head=pm[1], tail=pm[2])
    anchor = ""
    if β.name ∉ [:MATH_A, :MATH_I]
        # NOTE: in the future if allow equation tags, then will need an `if`
        # here and only increment if there's no tag. For now just use numbers.

        # increment equation counter
        JD_LOC_EQDICT[JD_LOC_EQDICT_COUNTER] += 1

        # check if there's a label, if there is, add that to the dictionary
        matched = match(r"\\label{(.*?)}", inner)
        if !isnothing(matched)
            name   = refstring(strip(matched.captures[1]))
            anchor = "<a id=\"$name\"></a>"
            inner  = replace(inner, r"\\label{.*?}" => "")
            # store the label name and associated number
            JD_LOC_EQDICT[name] = JD_LOC_EQDICT[JD_LOC_EQDICT_COUNTER]
        end
    end
    inner *= EOS

    return anchor * pm[3] * convert_md_math(inner, lxdefs, from(β)) * pm[4]
end
