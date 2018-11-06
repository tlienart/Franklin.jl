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
