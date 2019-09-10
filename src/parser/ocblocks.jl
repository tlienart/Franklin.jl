"""
$(SIGNATURES)

Find active blocks between an opening token (`otoken`) and a closing token `ctoken`. These can be
nested (e.g. braces). Return the list of such blocks. If `deactivate` is `true`, all the tokens
within the block will be marked as inactive (for further, separate processing).
"""
function find_ocblocks(tokens::Vector{Token}, ocproto::OCProto;
                       inmath=false)::Tuple{Vector{OCBlock}, Vector{Token}}

    ntokens       = length(tokens)
    active_tokens = ones(Bool, length(tokens))
    ocblocks      = Vector{OCBlock}()
    nestable      = ocproto.nest

    # go over active tokens check if there's an opening token
    # if so look for the closing one and push
    for (i, τ) ∈ enumerate(tokens)
        # only consider active and opening tokens
        (active_tokens[i] & (τ.name == ocproto.otok)) || continue
        # if nestable, need to keep track of the balance
        if nestable
            # inbalance ≥ 0, 0 if all opening tokens are closed
            inbalance = 1 # we've seen an opening token
            j = i # index for the closing token
            while !iszero(inbalance) & (j < ntokens)
                j += 1
                inbalance += ocbalance(tokens[j], ocproto)
            end
            if inbalance > 0
                throw(OCBlockError("I found at least one opening  token " *
                                   "'$(ocproto.otok)' that is not closed properly."))
            end
        else
            # seek forward to find the first closing token
            j = findfirst(cτ -> (cτ.name ∈ ocproto.ctok), tokens[i+1:end])
            # error if no closing token is found
            if isnothing(j)
                throw(OCBlockError("I found the opening token '$(τ.name)' but not " *
                                   "the corresponding closing token."))
            end
            j += i
        end
        push!(ocblocks, OCBlock(ocproto.name, τ => tokens[j]))

        # remove processed tokens and tokens within blocks except if
        # it's a brace block in a math environment.
        span = ifelse((ocproto.name == :LXB) & inmath, [i, j], i:j)
        active_tokens[span] .= false
    end
    return ocblocks, tokens[active_tokens]
end


"""
$(SIGNATURES)

Helper function to update the inbalance counter when looking for the closing token of a block with
nesting. Adds 1 if the token corresponds to an opening token, removes 1 if it's a closing token and
0 otherwise.
"""
function ocbalance(τ::Token, ocp::OCProto)::Int
    (τ.name == ocp.otok) && return 1
    (τ.name ∈  ocp.ctok) && return -1
    return 0
end


"""
$(SIGNATURES)

Convenience function to find all ocblocks e.g. such as `MD_OCBLOCKS`. Returns a vector of vectors
of ocblocks.
"""
function find_all_ocblocks(tokens::Vector{Token}, ocplist::Vector{OCProto}; inmath=false)

    ocbs_all = Vector{OCBlock}()
    for ocp ∈ ocplist
        ocbs, tokens = find_ocblocks(tokens, ocp; inmath=inmath)
        append!(ocbs_all, ocbs)
    end
    # it may happen that a block is contained in a larger escape block.
    # For instance this can happen if there is a code block in an escape block (see e.g. #151).
    # To fix this, we browse the escape blocks in backwards order and check if there is any other
    # block within it.
    i = length(ocbs_all)
    active = ones(Bool, i)
    all_heads = from.(ocbs_all)
    while i > 1
        cur_ocb = ocbs_all[i]
        if active[i] && cur_ocb.name ∈ MD_OCB_ESC
            # find all blocks within the span of this block, deactivate all of them
            cur_head = all_heads[i]
            cur_tail = to(cur_ocb)
            mask = filter(j -> active[j] && cur_head < all_heads[j] < cur_tail, 1:i-1)
            active[mask] .= false
        end
        i -= 1
    end
    deleteat!(ocbs_all, map(!, active))
    return ocbs_all, tokens
end


"""
$(SIGNATURES)

Merge vectors of blocks by order of appearance of the blocks.
"""
function merge_blocks(lvb::Vector{<:AbstractBlock}...)
    blocks = vcat(lvb...)
    sort!(blocks, by=(β->from(β)))
    return blocks
end


"""
$(SIGNATURES)

Find indented lines.
"""
function find_indented_blocks(tokens::Vector{Token}, st::String)::Vector{Token}
    # index of the line return tokens
    lr_idx = [j for j in eachindex(tokens) if tokens[j].name == :LINE_RETURN]
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
        tokens[lr_idx[i]] = Token(:LR_INDENT, subs(st, start, start+length(indent)))
    end
    return tokens
end


"""
$SIGNATURES

When two indented code blocks follow each other and there's nothing in between (empty line(s)),
merge them into a super block.
"""
function merge_indented_code_blocks!(blocks::Vector{OCBlock}, mds::String)::Nothing
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

Helper function to [`merge_indented_code_blocks`](@ref).
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
