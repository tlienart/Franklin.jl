"""
    convert_html(hs, allvars)

Convert a judoc html string into a html string.
"""
function convert_html(hs::AbstractString, allvars::Dict)
    # Tokenize
    tokens = find_tokens(hs, HTML_TOKENS, HTML_1C_TOKENS)
    # Find hblocks ( {{ ... }})
    hblocks, tokens = find_html_hblocks(tokens)
    # Find qblocks (qualify the hblocks)
    qblocks = qualify_html_hblocks(hblocks)
    # Find overall conditional blocks (if ... elseif ... else ...  end)
    cblocks, qblocks = find_html_cblocks(qblocks)
    # Get the list of blocks to process
    hblocks = merge_fblocks_cblocks(qblocks, cblocks)
    # construct the final html
    # 🚫🚫🚫🚫🚫🚫🚫🚫🚫🚫🚫🚫🚫🚫🚫🚫🚫🚫🚫🚫
    pieces = Vector{AbstractString}()
    head = 1
    for (i, hb) ∈ enumerate(hblocks)
        fromhb = from(hb)
        (head < fromhb) && push!(pieces, subs(hs, head, fromhb-1))
        push!(pieces, convert_hblock(hb, allvars))
        head = to(hb) + 1
    end
    strlen = lastindex(hs)
    (head < strlen) && push!(pieces, subs(hs, head, strlen))
    return prod(pieces)
end


"""
    convert_hblock(β, allvars)

Helper function to process an individual block when the block is a `HFun`.
"""
function convert_hblock(β::HFun, allvars::Dict)
    fname = lowercase(β.fname)
    fname == "fill"   && return hfun_fill(β.params, allvars)
    fname == "insert" && return hfun_insert(β.params)
    # unknown function
    warn("I found a function block '{{$fname ...}}' but I don't recognise this function name. Ignoring.")
    return subs(hs, from(β), to(β))
end


"""
    convert_hblock(β, allvars)

Helper function to process an individual block when the block is a `HCond`.
"""
function convert_hblock(β::HCond, allvars::Dict)
    # check that the bool vars exist
    allconds = [β.init_cond, β.sec_conds...]
    has_else = (length(β.actions) == 1 + length(β.sec_conds) + 1)
    all(c -> haskey(allvars, c), allconds) || error("At least one of the booleans in a conditional html block could not be found. Verify.")
    k = findfirst(c -> allvars[c].first, allconds)
    if isnothing(k)
        haselse || return ""
        partial = β.actions[end]
    else
        partial = β.actions[k]
    end
    return convert_html(partial, allvars)
end
