"""
$(SIGNATURES)

Helper function to process an individual block when the block is a `HCond` such as `{{ if
showauthor }} {{ fill author }} {{ end }}`.
"""
function convert_hblock(β::HCond, allvars::JD_VAR_TYPE, fpath::AbstractString="")::String
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

    # NOTE the String(...) is necessary here as to avoid problematic indexing further on
    return convert_html(String(partial), allvars, fpath)
end

"""
$(SIGNATURES)

Helper function to process an individual block when the block is a `HIsDef` such as `{{ ifdef
author }} {{ fill author }} {{ end }}`. Which checks if a variable exists and if it does, applies
something.
"""
function convert_hblock(β::HCondDef, allvars::JD_VAR_TYPE, fpath::AbstractString="")::String
    hasvar = haskey(allvars, β.vname)
    # check if the corresponding bool is true and if so, act accordingly
    doaction = ifelse(β.checkisdef, hasvar, !hasvar)
    doaction && return convert_html(String(β.action), allvars, fpath::AbstractString)
    # default = do nothing
    return ""
end

"""
$(SIGNATURES)

Helper function to process an individual block when the block is a `HIsPage` such as `{{ ispage
path/to/page}} ... {{end}}`. Which checks if the current page is a given one and applies something
if that's the case (useful to handle different layouts on different pages).
"""
function convert_hblock(β::HCondPage, allvars::JD_VAR_TYPE, fpath::AbstractString="")::String
    # get the relative paths so assuming fpath == joinpath(JD_PATHS[:in], rel_path)
    rpath = replace(fpath, JD_PATHS[:in] => "")
    rpath = replace(rpath, Regex("^$(escape_string(PATH_SEP))pages$(escape_string(PATH_SEP))") =>
                                 "$(PATH_SEP)pub$(PATH_SEP)")
    # rejoin and remove the extension
    rel_path = splitext(rpath)[1]
    # compare with β.pnames
    inpage = any(page -> splitext(page)[1] == rel_path, β.pages)
    # check if the corresponding bool is true and if so, act accordingly
    doaction = ifelse(β.checkispage, inpage, !inpage)
    doaction && return convert_html(String(β.action), allvars, fpath::AbstractString)
    # default = do nothing
    return ""
end
