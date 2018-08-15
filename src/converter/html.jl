"""
    convert_html(hs, allvars)

Convert a judoc html string into a html string.
"""
function convert_html(hs::String, allvars::Dict)
    # Tokenize
    tokens = find_tokens(hs, HTML_TOKENS, HTML_1C_TOKENS)
    # Find hblocks ( {{ ... }})
    hblocks, tokens = find_html_hblocks(tokens)
    # Find qblocks (qualify the hblocks)
    qblocks = qualify_html_hblocks(hblocks, hs)
    # Find overall conditional blocks (if ... elseif ... else ...  end)
    cblocks, qblocks = find_html_cblocks(qblocks)
    # Get the list of blocks to process
    allblocks = get_html_allblocks(qblocks, cblocks, endof(hs))

    hs = prod(convert_html__procblock(β, hs, allvars) for β ∈ allblocks)
end


"""
    convert_html__procblock(β)

Helper function to process an individual block.
"""
function convert_html__procblock(β::Union{Block, <:HBlock, HCond}, hs::String,
                                 allvars::Dict)
    # if it's just a remain block, plug in "as is"
    ((typeof(β) == Block) && β.name == :REMAIN) && return hs[β.from:β.to]

    # if it's a conditional block, need to find the span corresponding
    # to the variable that is true (or the else block)
    if typeof(β) == HCond
        # check that the bool vars exist
        allconds = [β.vcond1, β.vconds...]
        haselse = (length(β.dofrom) == 1 + length(β.vconds) + 1)
        all(c -> haskey(allvars, c), allconds) || error("At least one of the booleans in the conditional block could not be found. Verify.")
        k = findfirst(c -> allvars[c].first, allconds)
        if (k == nothing)
            haselse || return ""
            partial = hs[β.dofrom[end]:β.doto[end]]
        else
            partial = hs[β.dofrom[k]:β.doto[k]]
        end
        return convert_html(partial, allvars)
    # function block
    elseif typeof(β) == HFun
        fname = lowercase(β.fname)
        fname == "fill"     && return hfun_fill(β.params, allvars)
        fname == "insert"   && return hfun_insert(β.params)
        # unknown function
        warn("I found a function block '{{$(lowercase(β.fname)) ...}}' but I don't know this function name. Ignoring.")
        return hs[β.from:β.to]
    end
end
