"""
$(SIGNATURES)

Convert a Franklin-Markdown file read as `mds` into a Franklin HTML string.
Returns the html string as well as a dictionary of page variables.

**Arguments**

* `mds`:         the markdown string to process
* `pre_lxdefs`:  a vector of `LxDef` that are already available.

**Keyword arguments**

* `isrecursive=false`: a bool indicating whether the call is the parent call or
                        a child call
* `isinternal=false`:  a bool indicating whether the call stems from `fd2html`
                        in internal mode
* `isconfig=false`:    a bool indicating whether the file to convert is the
                        configuration file
* `has_mddefs=true`:   a bool indicating whether to look for definitions of
                        page variables
"""
function convert_md(mds::AS,
                    pre_lxdefs::Vector{LxDef}=collect(values(GLOBAL_LXDEFS));
                    isrecursive::Bool=false,
                    isinternal::Bool=false,
                    isconfig::Bool=false,
                    has_mddefs::Bool=true )::String
    # instantiate page dictionaries
    isrecursive || isinternal || set_page_env()
    # if we're given a substring, force it to a string
    mds = String(mds)

    #
    # Parsing of the markdown string
    # (to find latex command, latex definitions, math envs etc.)
    #

    # ------------------------------------------------------------------------
    #> 1. Tokenize
    tokens = find_tokens(mds, MD_TOKENS, MD_1C_TOKENS)
    # distinguish fnref/fndef
    validate_footnotes!(tokens)
    # ignore header tokens that are not at the start of a line
    validate_headers!(tokens)
    #> 1b. Find indented blocks (ONLY if not recursive to avoid ambiguities!)
    if !isrecursive
        find_indented_blocks!(tokens, mds)
        if has_mddefs
            # look for multi-line definitions, for those that meet the
            # requirements, discard *all* tokens in the span leaving only
            # the opening and closing one. Note: expressions will be parsed
            # twice as a result but really it's negligible time.
            preprocess_candidate_mddefs!(tokens)
        end
        # any remaining indented lines that don't meet the requirements for
        # an indented code block get removed here
        filter_lr_indent!(tokens, mds)
    end

    # ------------------------------------------------------------------------
    #> 2. Open-Close blocks (OCBlocks)
    #>> a. find them
    blocks, tokens  = find_all_ocblocks(tokens, MD_OCB)
    toks_pre_ocb    = deepcopy(tokens) # see find_double_brace_blocks
    #>> a'. find the rest
    blocks2, tokens = find_all_ocblocks(tokens, vcat(MD_OCB2, MD_OCB_MATH))
    append!(blocks, blocks2)
    #>> b. merge CODE_BLOCK_IND which are separated by emptyness
    merge_indented_blocks!(blocks, mds)
    #>> b'. only keep indented code blocks which are not contained in larger
    # blocks (#285)
    filter_indented_blocks!(blocks)
    #>> c. now that blocks have been found, line-returns can be dropped
    filter!(τ -> τ.name ∉ L_RETURNS, tokens)
    #>> e. keep track of literal content of possible link definitions to use
    validate_and_store_link_defs!(blocks)

    # ------------------------------------------------------------------------
    #> 3. LaTeX commands
    #>> a. find "newcommands", update active blocks/braces
    lxdefs, tokens, braces, blocks = find_lxdefs(tokens, blocks)
    #>> b. if any lxdefs are given in the context, merge them. `pastdef` specifies
    # that the definitions appeared "earlier"
    lprelx = length(pre_lxdefs)
    (lprelx > 0) && (lxdefs = cat(pastdef.(pre_lxdefs), lxdefs, dims=1))
    #>> c. find latex commands
    lxcoms, _ = find_lxcoms(tokens, lxdefs, braces)

    #> 3[ex]. find double brace blocks, note we do it on pre_ocb tokens
    # as the step `find_all_ocblocks` possibly found and deactivated {...}.
    dbb = find_double_brace_blocks(toks_pre_ocb)

    # ------------------------------------------------------------------------
    #> 4. Page variable definition (mddefs), also if in config, update lxdefs
    if has_mddefs
        process_mddefs(blocks, isconfig)
    end
    #> 4.b if config, update global lxdefs as well
    if isconfig
        for lxd ∈ lxdefs
            GLOBAL_LXDEFS[lxd.name] = pastdef(lxd)
        end
        # if it's the config file we don't need to go further
        return ""
    end

    # ------------------------------------------------------------------------
    #> 5. Process special characters and html entities so that they can be
    # injected as they are in the HTML later
    sp_chars = find_special_chars(tokens)

    # ========================================================================
    #
    # Forming of the html string
    #
    # filter out the fnrefs that are left (still active)
    # and add them to the blocks to insert
    fnrefs = filter!(τ -> τ.name == :FOOTNOTE_REF, tokens)

    #> 1. Merge all the blocks that will need further processing before
    # insertion
    b2insert = merge_blocks(lxcoms, deactivate_divs(blocks),
                            sp_chars, fnrefs, dbb)

    #> 2. Form intermediate markdown + html
    inter_md, mblocks = form_inter_md(mds, b2insert, lxdefs)
    inter_html = md2html(inter_md; stripp=isrecursive)

    #> 3. Plug resolved blocks in partial html to form the final html
    hstring = convert_inter_html(inter_html, mblocks, lxdefs)

    # final var adjustment, infer title if not given
    if isnothing(locvar("title")) && !isempty(PAGE_HEADERS)
        set_var!(LOCAL_VARS, "title", first(values(PAGE_HEADERS))[1])
    end

    # Return the string
    return hstring
end


"""
$(SIGNATURES)

Same as `convert_md` except tailored for conversion of the inside of a math
block (no command definitions, restricted tokenisation to latex tokens). The
offset keeps track of where the math block was, which is useful to check
whether any of the latex command used in the block have not yet been defined.

**Arguments**

* `ms`:     the string to convert
* `lxdefs`: existing latex definitions prior to the math block
* `offset`: where the mathblock is with respect to the parent string
"""
function convert_md_math(ms::AS, lxdefs::Vector{LxDef}=Vector{LxDef}(),
                         offset::Int=0)::String
    # if a substring is given, copy it as string
    ms = String(ms)
    #
    # Parsing of the markdown string
    # (to find latex command, latex definitions, math envs etc.)
    #

    #> 1. Tokenize (with restricted set)
    tokens = find_tokens(ms, MD_TOKENS_LX, MD_1C_TOKENS_LX)

    #> 2. Find braces and drop line returns thereafter
    blocks, tokens = find_all_ocblocks(tokens, MD_OCB_ALL, inmath=true)
    braces = filter(β -> β.name == :LXB, blocks)

    #> 3. Find latex commands (indicate we're in a math environment + offset)
    lxcoms, _ = find_lxcoms(tokens, lxdefs,  braces, offset; inmath=true)

    #
    # Forming of the html string
    # (see `form_inter_md`, it's similar but simplified since there are fewer
    # conditions)
    #
    htmls = IOBuffer()

    strlen   = lastindex(ms)
    len_lxc  = length(lxcoms)
    next_lxc = iszero(len_lxc) ? BIG_INT : from(lxcoms[1])

    # counters to keep track of where we are and which command we're looking at
    head, lxc_idx = 1, 1
    while (next_lxc < BIG_INT) && (head < strlen)
        # add anything that may occur before the first command
        (head < next_lxc) && write(htmls, subs(ms, head, prevind(ms, next_lxc)))
        # add the first command after resolving, bool to indicate that we're in
        # a math env
        write(htmls, resolve_lxcom(lxcoms[lxc_idx], lxdefs, inmath=true))
        # move the head to after the lxcom and increment the com counter
        head     = nextind(ms, to(lxcoms[lxc_idx]))
        lxc_idx += 1
        next_lxc = from_ifsmaller(lxcoms, lxc_idx, len_lxc)
    end
    # add anything after the last command
    (head ≤ strlen) && write(htmls, chop(ms, head=prevind(ms, head), tail=0))
    return String(take!(htmls))
end


"""
INSERT

String that is plugged as a placeholder of blocks that need further processing.
The spaces allow to handle overzealous inclusion of `<p>...</p>` from the base
Markdown to HTML conversion.
"""
const INSERT     = " ##FDINSERT## "
const INSERT_    = strip(INSERT)
const INSERT_PAT = Regex(INSERT_)
const INSERT_LEN = length(INSERT_)


"""
Form an intermediate MD file where special blocks are replaced by a marker
(`INSERT`) indicating that a piece will need to be plugged in there later.

**Arguments**

* `mds`:    the (sub)string to convert
* `blocks`: vector of blocks
* `lxdefs`: existing latex definitions prior to the math block
"""
function form_inter_md(mds::AS, blocks::Vector{<:AbstractBlock},
                       lxdefs::Vector{LxDef}
                       )::Tuple{String, Vector{AbstractBlock}}
    strlen  = lastindex(mds)
    intermd = IOBuffer()
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

    # keep track of a few counters (where we are, which block, which command)
    head, b_idx, lxd_idx = 1, 1, first_lxd

    while (nxtidx < BIG_INT) & (head < strlen)
        # check if there's anything before head and next block and write it
        (head < nxtidx) && write(intermd, subs(mds, head, prevind(mds, nxtidx)))
        # check whether it's a block first or a newcommand first
        if b_or_lxd # it's a block, check if should be written
            β = blocks[b_idx]
            # check whether the block should be skipped
            if isa(β, OCBlock) && β.name ∈ MD_OCB_IGNORE
                head = nextind(mds, to(β))
            else
                if isa(β, OCBlock) && β.name ∈ MD_HEADER
                    # this is a trick to allow whatever follows the title to be
                    # properly parsed by Markdown.parse; it could otherwise
                    # cause issues for instance if a table starts immediately
                    # after the title
                    write(intermd, INSERT * "\n ")
                else
                    write(intermd, INSERT)
                end
                push!(mblocks, β)
                head = nextind(mds, to(blocks[b_idx]))
            end
            b_idx += 1
            next_b = from_ifsmaller(blocks, b_idx, len_b)
        else
            # newcommand or ignore --> skip, increase counters, move head
            head     = nextind(mds, to(lxdefs[lxd_idx]))
            lxd_idx += 1
            next_lxd = from_ifsmaller(lxdefs, lxd_idx, len_lxd)
        end
        # check which block is next
        b_or_lxd = (next_b < next_lxd)
        nxtidx = min(next_b, next_lxd)
    end
    # add whatever is after the last block
    (head <= strlen) && write(intermd, subs(mds, head, strlen))

    # combine everything and return
    return String(take!(intermd)), mblocks
end


"""
$(SIGNATURES)

Take a partial markdown string with the `INSERT` marker and plug in the
appropriately processed block.

**Arguments**

* `ihtml`:  the intermediary html string (with `INSERT`)
* `blocks`: vector of blocks
* `lxdefs`: latex context
"""
function convert_inter_html(ihtml::AS,
                            blocks::Vector{<:AbstractBlock},
                            lxdefs::Vector{LxDef})::String
    # Find the INSERT indicators
    allmatches = collect(eachmatch(INSERT_PAT, ihtml))
    strlen = lastindex(ihtml)

    # write the pieces of the final html in order, gradually processing the
    # blocks to insert
    htmls = IOBuffer()
    head  = 1
    for (i, m) ∈ enumerate(allmatches)
        # two cases can happen based on whitespaces around an insertion that
        # we want to get rid of, potentially both happen simultaneously.
        # 1. <p>##FDINSERT##...
        # 2. ...##FDINSERT##</p>
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
        iend = m.offset + INSERT_LEN
        c2a  = nextind(ihtml, iend)
        c2b  = nextind(ihtml, iend, 4)  # </p*
        c20  = nextind(ihtml, iend, 10) # </p>\n</li*

        hasli2 = (c20 ≤ strlen) && ihtml[c2a:c20] == "</p>\n</li>"
        !(hasli2) && (c2b ≤ strlen - 4) && ihtml[c2a:c2b] == "</p>" && (δ2 = 4)

        # write whatever is at the front, skip the extra space if still present
        prev = prevind(ihtml, m.offset - δ1)
        if prev > 0 && ihtml[prev] == ' '
            prev = prevind(ihtml, prev)
        end
        (head ≤ prev) && write(htmls, subs(ihtml, head:prev))
        # move head appropriately
        head = iend + δ2
        if head ≤ strlen
            head = ifelse(ihtml[head] in (' ', '>'), nextind(ihtml, head), head)
        end
        # store the resolved block
        write(htmls, convert_block(blocks[i], lxdefs))
    end
    # store whatever is after the last INSERT if anything
    (head ≤ strlen) && write(htmls, subs(ihtml, head:strlen))
    # return the full string
    return String(take!(htmls))
end


"""
$(SIGNATURES)

Convenience function to process markdown definitions `@def ...` as appropriate.
Depending on `isconfig`, will update `GLOBAL_VARS` or `LOCAL_VARS`.

**Arguments**

* `blocks`:    vector of active docs
* `isconfig`:  whether the file being processed is the config file
                (--> global page variables)
"""
function process_mddefs(blocks::Vector{OCBlock}, isconfig::Bool)::Nothing
    # Find all markdown definitions (MD_DEF) blocks
    mddefs = filter(β -> (β.name == :MD_DEF), blocks)
    # empty container for the assignments
    assignments = Vector{Pair{String, String}}()
    # go over the blocks, and extract the assignment
    for (i, mdd) ∈ enumerate(mddefs)
        inner = strip(content(mdd))
        m = match(ASSIGN_PAT, inner)
        if isnothing(m)
            @warn "Found delimiters for an @def environment but it didn't " *
                  "have the right @def var = ... format. Verify (ignoring " *
                  "for now)."
            continue
        end
        vname, vdef = m.captures[1:2]
        push!(assignments, (String(vname) => String(vdef)))
    end
    # if in config file, update `GLOBAL_VARS` and `GLOBAL_LXDEFS`
    if isconfig
        set_vars!(GLOBAL_VARS, assignments)
    else
        set_vars!(LOCAL_VARS, assignments)
    end
    return nothing
end
