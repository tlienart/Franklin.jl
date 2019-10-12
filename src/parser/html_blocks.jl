"""
$(SIGNATURES)

Given `{{ ... }}` blocks, identify what kind of blocks they are and return a vector
of qualified blocks of type `AbstractBlock`.
"""
function qualify_html_hblocks(blocks::Vector{OCBlock})::Vector{AbstractBlock}

    qb = Vector{AbstractBlock}(undef, length(blocks))

    # TODO improve this (if there are many blocks this would be slow)
    for (i, β) ∈ enumerate(blocks)
        # if block {{ if v }}
        m = match(HBLOCK_IF_PAT, β.ss)
        isnothing(m) || (qb[i] = HIf(β.ss, m.captures[1]); continue)
        # else block {{ else }}
        m = match(HBLOCK_ELSE_PAT, β.ss)
        isnothing(m) || (qb[i] = HElse(β.ss); continue)
        # else if block {{ elseif v }}
        m = match(HBLOCK_ELSEIF_PAT, β.ss)
        isnothing(m) || (qb[i] = HElseIf(β.ss, m.captures[1]); continue)
        # end block {{ end }}
        m = match(HBLOCK_END_PAT, β.ss)
        isnothing(m) || (qb[i] = HEnd(β.ss); continue)
        # ---
        # isdef block
        m = match(HBLOCK_ISDEF_PAT, β.ss)
        isnothing(m) || (qb[i] = HIsDef(β.ss, m.captures[1]); continue)
        # ifndef block
        m = match(HBLOCK_ISNOTDEF_PAT, β.ss)
        isnothing(m) || (qb[i] = HIsNotDef(β.ss, m.captures[1]); continue)
        # ---
        # ispage block
        m = match(HBLOCK_ISPAGE_PAT, β.ss)
        isnothing(m) || (qb[i] = HIsPage(β.ss, split(m.captures[1])); continue)
        # isnotpage block
        m = match(HBLOCK_ISNOTPAGE_PAT, β.ss)
        isnothing(m) || (qb[i] = HIsNotPage(β.ss, split(m.captures[1])); continue)
        # ---
        # function block {{ fname v1 v2 ... }}
        m = match(HBLOCK_FUN_PAT, β.ss)
        isnothing(m) || (qb[i] = HFun(β.ss, m.captures[1], split(m.captures[2])); continue)
        # ---
        # function toc {{toc}}
        m = match(HBLOCK_TOC_PAT, β.ss)
        isnothing(m) || (qb[i] = HFun(β.ss, "toc", String[]); continue)

        throw(HTMLBlockError("I found a HBlock that did not match anything, " *
                             "verify '$(β.ss)'"))
    end
    return qb
end


"""Blocks that can open a conditional block."""
const HTML_OPEN_COND = Union{HIf,HIsDef,HIsNotDef,HIsPage,HIsNotPage}


"""
$SIGNATURES

Internal function to balance conditional blocks. See [`process_html_qblocks`](@ref).
"""
hbalance(::HTML_OPEN_COND) = 1
hbalance(::HEnd) = -1
hbalance(::AbstractBlock) = 0
