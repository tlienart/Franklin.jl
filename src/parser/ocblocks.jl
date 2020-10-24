"""
$(SIGNATURES)

Find active blocks between an opening token (`otoken`) and a closing token
`ctoken`. These can be nested (e.g. braces). Return the list of such blocks.
"""
function find_ocblocks(tokens::Vector{Token}, ocproto::OCProto;
                       inmath=false)::Tuple{Vector{OCBlock}, Vector{Token}}

    ntokens       = length(tokens)
    active_tokens = ones(Bool, length(tokens))
    ocblocks      = OCBlock[]
    nestable      = ocproto.nest

    # go over active tokens check if there's an opening token
    # if so look for the closing one and push
    for (i, τ) ∈ enumerate(tokens)
        # only consider active and opening tokens
        (active_tokens[i] && (τ.name == ocproto.otok)) || continue
        # if nestable, need to keep track of the balance
        if nestable
            # inbalance ≥ 0, 0 if all opening tokens are closed
            inbalance = 1 # we've seen an opening token
            j = i # index for the closing token
            while !iszero(inbalance) && (j < ntokens)
                j += 1
                inbalance += ocbalance(tokens[j], ocproto)
            end
            if inbalance > 0
                throw(OCBlockError(
                    "I found at least one opening token '$(ocproto.otok)' " *
                    "that is not closed properly.", context(τ)))
            end
        else
            # seek forward to find the first closing token
            j = findfirst(cτ -> (cτ.name ∈ ocproto.ctok), tokens[i+1:end])
            # error if no closing token is found
            if isnothing(j)
                throw(OCBlockError("I found the opening token '$(τ.name)' " *
                                   "but not the corresponding closing token.",
                                   context(τ)))
            end
            j += i
        end
        push!(ocblocks, OCBlock(ocproto.name, τ => tokens[j]))

        # remove processed tokens and tokens within blocks except if
        # it's a brace block in a math environment.
        span = ifelse((ocproto.name == :LXB) && inmath, [i, j], i:j)
        active_tokens[span] .= false
    end
    return ocblocks, tokens[active_tokens]
end


"""
$(SIGNATURES)

Helper function to update the inbalance counter when looking for the closing
token of a block with nesting. Adds 1 if the token corresponds to an opening
token, removes 1 if it's a closing token and 0 otherwise.
"""
function ocbalance(τ::Token, ocp::OCProto)::Int
    (τ.name == ocp.otok) && return 1
    (τ.name ∈  ocp.ctok) && return -1
    return 0
end

"""
$(SIGNATURES)

Helper function to update the inbalance counter when looking for the closing
token of an environment block. Adds 1 if the token corresponds to an opening
token, removes 1 if it's a closing token and 0 otherwise.
"""
function envbalance(τ::Token, env::AS)::Int
    if τ.name == :LX_BEGIN && envname(τ) == env
        return 1
    elseif τ.name == :LX_END && envname(τ) == env
        return -1
    end
    return 0
end

"""
$(SIGNATURES)

Convenience function to find all ocblocks e.g. such as `MD_OCBLOCKS`. Returns a
vector of vectors of ocblocks.
"""
function find_all_ocblocks(tokens::Vector{Token}, ocplist::Vector{OCProto};
                           inmath=false)
    ocbs_all = Vector{OCBlock}()
    for ocp ∈ ocplist
        ocbs, tokens = find_ocblocks(tokens, ocp; inmath=inmath)
        append!(ocbs_all, ocbs)
    end
    return ocbs_all, tokens
end

"""
$SIGNATURES

Deactivate blocks inside other blocks when the outer block is bound to be
reprocessed. There's effectively two cases:
1. (solved here) when a block is inside a larger 'escape' block.
2. (solved in `check_and_merge_indented_blocks!`) when an indented code block
    is contained inside a larger block.
"""
function deactivate_inner_blocks!(blocks::Vector{OCBlock}, nin=MD_OCB_NO_INNER)
    ranges = Vector{Pair{Int,Int}}()
    isempty(blocks) && return ranges
    # see #444 it's important to ensure the blocks are sorted and they now
    # may not be given that we're finding them in 2 passes.
    sort!(blocks, by=(β->from(β)))
    # CASE 1: block inside a larger escape block.
    #   this can happen if there is a code block in an escape block
    #   (see e.g. #151) or if there's indentation in a math block.
    i       = 1
    nb      = length(blocks)
    active  = ones(Bool, nb)
    heads   = from.(blocks)
    while i <= nb
        cblock = blocks[i]
        # is the block active and is it a "no-inner"?
        if active[i] && cblock.name ∈ nin
            # find all blocks within the span of this block, deactivate them
            chead = heads[i]
            ctail = to(cblock)
            # keep track of the range
            push!(ranges, (chead => ctail))
            # look at all blocks starting after the current one that may
            # be within its span (note that, at worst, we have a few thousand
            # blocks here so that it doesn't need to be super optimised...)
            mask = filter(j -> active[j] && chead < heads[j] < ctail, i+1:nb)
            active[mask] .= false
        end
        i += 1
    end
    deleteat!(blocks, map(!, active))
    return ranges
end

"""
$SIGNATURES

Deactivate blocks that are contained in an environment so that they be reprocessed later.
"""
function deactivate_blocks_in_envs!(blocks, lxenvs)
    lxe_ranges = Vector{Pair{Int,Int}}()
    for lxe in lxenvs
        range = from(lxe) => to(lxe)
        any(r -> r.first < range.first && r.second > range.second, lxe_ranges) && continue
        push!(lxe_ranges, range)
    end
    inner_blocks = Int[]
    for i in eachindex(blocks)
        block = blocks[i]
        range = from(block) => to(block)
        if any(r -> r.first < range.first && r.second > range.second, lxe_ranges)
            push!(inner_blocks, i)
        end
    end
    deleteat!(blocks, inner_blocks)
    return lxe_ranges
end

"""
$SIGNATURES

Given ranges found by `deactivate_inner_blocks!` deactivate double brace blocks
that are within those ranges (they will be reprocessed later).
"""
function deactivate_inner_dbb!(dbb, ranges)
    isempty(dbb) && return nothing
    isempty(ranges) && return nothing
    active = ones(Bool, length(dbb))
    for (i, d) in enumerate(dbb)
        hd, td = from(d), to(d)
        r = findfirst(r -> r.first < hd && td < r.second, ranges)
        isnothing(r) || (active[i] = false)
    end
    deleteat!(dbb, map(!, active))
    return nothing
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
$SIGNATURES

Take a list of token and return those corresponding to special characters or
html entities wrapped in `HTML_SPCH` types (will be left alone by the markdown
conversion and be inserted as is in the HTML).
"""
function find_special_chars(tokens::Vector{Token})
    spch = Vector{HTML_SPCH}()
    isempty(tokens) && return spch
    for τ in tokens
        τ.name == :CHAR_ASTERISK    && push!(spch, HTML_SPCH(τ.ss, "&#42;"))
        τ.name == :CHAR_UNDERSCORE  && push!(spch, HTML_SPCH(τ.ss, "&#95;"))
        τ.name == :CHAR_ATSIGN      && push!(spch, HTML_SPCH(τ.ss, "&#64;"))
        τ.name == :CHAR_BACKSPACE   && push!(spch, HTML_SPCH(τ.ss, "&#92;"))
        τ.name == :CHAR_BACKTICK    && push!(spch, HTML_SPCH(τ.ss, "&#96;"))
        τ.name == :CHAR_LINEBREAK   && push!(spch, HTML_SPCH(τ.ss, "<br/>"))
        τ.name == :EMOJI            && push!(spch, HTML_SPCH(τ.ss, emoji(τ)))
        τ.name == :CHAR_HTML_ENTITY &&
            validate_html_entity(τ.ss) && push!(spch, HTML_SPCH(τ.ss))
    end
    return spch
end
