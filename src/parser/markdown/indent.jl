"""
$(SIGNATURES)

Find markers for indented lines (i.e. a line return followed by a tab or 4
spaces).
"""
function find_indented_blocks!(tokens::Vector{Token}, st::String)::Nothing
    # index of the line return tokens
    lr_idx = [j for j in eachindex(tokens) if tokens[j].name == :LINE_RETURN]
    remove = Int[]
    # go over all line return tokens; if they are followed by either four spaces
    # or by a tab, then check if the line is empty or looks like a list, otherwise
    # change the token for a LR_INDENT token which will be captured as part of code
    # blocks.
    for i in 1:length(lr_idx)-1
        # capture start and finish of the line (from line return to line return)
        start  = from(tokens[lr_idx[i]])   # first :LINE_RETURN
        finish = from(tokens[lr_idx[i+1]]) # next  :LINE_RETURN
        line   = subs(st, start, finish)
        indent = ""
        if startswith(line, "\n    ")
            indent = "    "
        elseif startswith(line, "\n\t")
            indent = "\t"
        else
            continue
        end
        # is there something on that line? if so, does it start with a list indicator
        # like `*`, `-`, `+` or [0-9](.|\)) ? in which case this takes precedence (commonmark)
        # TODO: document clearly that with fenced code blocks there are far fewer cases for issues
        code_line = subs(st, nextind(st, start+length(indent)), prevind(st, finish))
        scl       = strip(code_line)
        isempty(scl) && continue
        # list takes precedence (this may cause clash but then just use fenced code blocks...)
        looks_like_a_list = scl[1] ∈ ('*', '-', '+') ||
                            (length(scl) ≥ 2 &&
                                scl[1] ∈ ('0', '1', '2', '3', '4', '5', '6', '7', '8', '9') &&
                                scl[2] ∈ ('.', ')'))
        looks_like_a_list && continue
        # if here, it looks like a code line (and will be considered as such)
        tokens[lr_idx[i]] = Token(:LR_INDENT, subs(st, start, start+length(indent)), i+1)
    end
    return nothing
end

"""
$(SIGNATURES)

In initial phase, discard all `:LR_INDENT` that don't meet the requirements for
an indented code block. I.e.: where the first  line is not preceded by a blank
line and then subsequently followed by indented lines.
"""
function filter_lr_indent!(vt::Vector{Token}, s::String)::Nothing
    tind_idx = [i for i in eachindex(vt) if vt[i].name == :LR_INDENT]
    isempty(tind_idx) && return nothing
    disable = zeros(Bool, length(tind_idx))
    open = false
    i    = 1
    while i <= length(tind_idx)
        t = vt[tind_idx[i]]
        if !open
            # check if previous line is blank
            prev_idx = prevind(s, from(t))
            if prev_idx < 1 || s[prev_idx] != '\n'
                disable[i] = true
            else
                open = true
            end
            i += 1
        else
            # if touching previous line, keep open and go to next
            prev = vt[tind_idx[i-1]]
            if prev.lno + 1 == t.lno
                i += 1
            else
                # otherwise close, and continue (will go to !open)
                open = false
                continue
            end
        end
    end
    for i in eachindex(disable)
        disable[i] || continue
        vt[tind_idx[i]] = Token(:LINE_RETURN, subs(vt[tind_idx[i]].ss, 1))
    end
    return nothing
end

"""
$SIGNATURES

When two indented code blocks follow each other and there's nothing in between
(empty line(s)), merge them into a super block.
"""
function merge_indented_blocks!(blocks::Vector{OCBlock}, mds::AS)::Nothing
    # indices of CODE_BLOCK_IND
    idx = [i for i in eachindex(blocks) if blocks[i].name == :CODE_BLOCK_IND]
    isempty(idx) && return
    # check if they're separated by something or nothing
    inter_space = [(subs(mds, to(blocks[idx[i]]), from(blocks[idx[i+1]])) |> strip |> length) > 0
                    for i in 1:length(idx)-1]

    curseq     = Int[] # to keep track of current list of blocks to merge
    del_blocks = Int[] # to keep track of blocks that will be removed afterwards

    # if there's no inter_space, add to the list, if there is, close and merge
    for i in eachindex(inter_space)
        if inter_space[i] && !isempty(curseq)
            # close and merge all in curseq and empty curseq
            form_super_block!(blocks, idx, curseq, del_blocks)
        elseif !inter_space[i]
            push!(curseq, i)
        end
    end
    !isempty(curseq) && form_super_block!(blocks, idx, curseq, del_blocks)
    # remove the blocks that have been merged
    deleteat!(blocks, del_blocks)
    return
end


"""
$SIGNATURES

Helper function to [`merge_indented_blocks`](@ref).
"""
function form_super_block!(blocks::Vector{OCBlock}, idx::Vector{Int},
                           curseq::Vector{Int}, del_blocks::Vector{Int})::Nothing
    push!(curseq, curseq[end]+1)
    first_block = blocks[idx[curseq[1]]]
    last_block  = blocks[idx[curseq[end]]]
    # replace the first block with the super block
    blocks[idx[curseq[1]]] = OCBlock(:CODE_BLOCK_IND, (otok(first_block) => ctok(last_block)))
    # append all blocks but the first to the delete list
    append!(del_blocks, curseq[2:end])
    empty!(curseq)
    return
end


"""
$SIGNATURES

Discard any indented block that is within a larger block to avoid ambiguities
(see #285).
"""
function filter_indented_blocks!(blocks::Vector{OCBlock})::Nothing
    # retrieve the indices of the indented blocks
    idx = [i for i in eachindex(blocks) if blocks[i].name == :CODE_BLOCK_IND]
    isempty(idx) && return nothing
    # keep track of the ones that are active
    active    = ones(Bool, length(idx))
    # retrieve their span
    indblocks = blocks[idx]
    froms     = indblocks .|> from
    tos       = indblocks .|> to
    # retrieve the max/min span for faster processing
    minfrom   = froms |> minimum
    maxto     = tos |> maximum
    update    = false
    # go over all blocks and check if they contain an indented block
    for block in blocks
        # discard if the block is before or after all indented blocks
        from_, to_ = from(block), to(block)
        (to_ < minfrom || from_ > maxto) && continue
        # otherwise check and deactivate if it's contained
        for k in eachindex(active)
            active[k] || continue
            indblock = blocks[idx[k]]
            if from_ < from(indblock) && to_ > to(indblock)
                active[k] = false
                update = true
            end
        end
        if update
            froms[.!active] .= typemax(Int)
            tos[.!active]   .= 0
            minfrom          = froms |> minimum
            maxto            = tos |> maximum
            update           = false
        end
    end
    deleteat!(blocks, idx[.!active])
    return nothing
end
