"""
    convert_html(hs, allvars)

Convert a judoc html string into a html string (i.e. replace {{ ... }} blocks).
"""
function convert_html(hs::String, allvars=Dict{String, Pair{Any, Tuple}}())

    # Tokenize
    tokens = find_tokens(hs, HTML_TOKENS, HTML_1C_TOKENS)

    # Find hblocks ({{ ... }})
    hblocks, tokens = find_all_ocblocks(tokens, HTML_OCB)
    filter!(hb -> hb.name != :COMMENT, hblocks)

    # Find qblocks (qualify the hblocks)
    qblocks = qualify_html_hblocks(hblocks)
    # Find overall conditional blocks (if ... elseif ... else ...  end)
    cblocks, qblocks = find_html_cblocks(qblocks)
    # Find conditional def blocks (ifdef / ifndef)
    cdblocks, qblocks = find_html_cdblocks(qblocks)

    # Get the list of blocks to process
    hblocks = merge_blocks(qblocks, cblocks, cdblocks)

    # construct the final html
    pieces = Vector{AbstractString}()
    head = 1
    for (i, hb) ∈ enumerate(hblocks)
        fromhb = from(hb)
        (head < fromhb) && push!(pieces, subs(hs, head, prevind(hs, fromhb)))
        push!(pieces, convert_hblock(hb, allvars))
        head = nextind(hs, to(hb))
    end
    strlen = lastindex(hs)
    (head < strlen) && push!(pieces, subs(hs, head, strlen))

    fhs = prod(pieces)
    δ = ifelse(endswith(fhs, "</p>\n") && !startswith(fhs, "<p>"), 5, 0)

    return chop(fhs, tail=δ)
end


"""
    JD_HTML_FUNS

Dictionary for special html functions. They can take two variables, the first
one `π` refers to the arguments passed to the function, the second one `ν`
refers to the page variables (i.e. the context) available to the function.
"""
const JD_HTML_FUNS = Dict{String, Function}(
    "fill"   => ((π, ν) -> hfun_fill(π, ν)),
    "insert" => ((π, _) -> hfun_insert(π)),
    "href"   => ((π, _) -> hfun_href(π)),
)


"""
    convert_hblock(β, allvars)

Helper function to process an individual block when the block is a `HFun`
such as `{{ fill author }}`.
"""
function convert_hblock(β::HFun, allvars::Dict)

    fn = lowercase(β.fname)
    haskey(JD_HTML_FUNS, fn) && return JD_HTML_FUNS[fn](β.params, allvars)

    # if here, then the function name is unknown, warn and ignore
    @warn "I found a function block '{{$fn ...}}' but I don't recognise this function name. Ignoring."
    return β.ss
end


"""
    convert_hblock(β, allvars)

Helper function to process an individual block when the block is a `HCond`
such as `{{ if showauthor }} {{ fill author }} {{ end }}`.
"""
function convert_hblock(β::HCond, allvars::Dict)

    # check that the bool vars exist
    allconds = [β.init_cond, β.sec_conds...]
    all(c -> haskey(allvars, c), allconds) || error("At least one of the booleans in a conditional html block could not be found. Verify.")

    # check if there's an "else" clause
    has_else = (length(β.actions) == 1 + length(β.sec_conds) + 1)
    # check the first clause that is verified
    k = findfirst(c -> allvars[c].first, allconds)
    # if none is verified, use the else clause if there is one or do nothing
    if isnothing(k)
        has_else || return ""
        partial = β.actions[end]
    # otherwise run the 1st one which is verified
    else
        partial = β.actions[k]
    end

    return convert_html(String(partial), allvars)
end


"""
    convert_hblock(β, allvars)

Helper function to process an individual block when the block is a `HIfDef`
such as `{{ ifdef author }} {{ fill author }} {{ end }}`. Which checks
if a variable exists and if it does, applies something.
"""
function convert_hblock(β::HCondDef, allvars::Dict)

    hasvar = haskey(allvars, β.vname)

    # check if the corresponding bool is true and if so, act accordingly
    doaction = ifelse(β.checkisdef, hasvar, !hasvar)
    doaction && return convert_html(String(β.action), allvars)

    # default = do nothing
    return ""
end
