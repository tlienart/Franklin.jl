"""
$(SIGNATURES)

Helper function to process an individual block when the block is a `HCond` such as `{{ if
showauthor }} {{ fill author }} {{ end }}`.
"""
function convert_html_block(β::HCond, allvars::PageVars)::String
    # check that the relevant bool variable exists
    allconds = (β.init_cond, β.sec_conds...)
    if any(c -> !haskey(allvars, c), allconds)
        throw(HTMLBlockError("At least one of the booleans in a conditional html block" *
                             "could not be found. The block is reproduced below:" *
                             "\n" * "-"^50 * "\n" * β.ss * "\n" * "-"^50 * "\n"))
    end
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
    # The String(...) is necessary here as to avoid problematic indexing further on
    return convert_html(String(partial), allvars)
end


"""
$(SIGNATURES)

Helper function to process an individual block when the block is a `HIsDef` such as `{{ isdef
author }} {{ fill author }} {{ end }}`. Which checks if a variable exists and if it does, applies
something.
"""
function convert_html_block(β::HCondDef, allvars::PageVars)::String
    hasvar = haskey(allvars, β.vname)
    # check if the corresponding bool is true and if so, act accordingly
    doaction = ifelse(β.checkisdef, hasvar, !hasvar)
    doaction && return convert_html(String(β.action), allvars)
    # default = do nothing
    return ""
end


"""
$(SIGNATURES)

Helper function to process an individual block when the block is a `HIsPage` such as `{{ ispage
path/to/page}} ... {{end}}`. Which checks if the current page is a given one and applies something
if that's the case (useful to handle different layouts on different pages).
"""
function convert_html_block(β::HCondPage, allvars::PageVars)::String
    # current path is relative to /src/ for instance /src/pages/blah.md -> pages/blah.md
    rpath = CUR_PATH[]
    # replace the `pages/` by `pub/`
    rpath = replace(rpath, Regex("^pages$(escape_string(PATH_SEP))") => "pub$(PATH_SEP)")
    # remove the extension
    rel_path = splitext(rpath)[1]
    # compare with β.pnames
    inpage = any(page -> splitext(page)[1] == rel_path, β.pages)
    # check if the corresponding bool is true and if so, act accordingly
    doaction = ifelse(β.checkispage, inpage, !inpage)
    doaction && return convert_html(String(β.action), allvars)
    # default = do nothing
    return ""
end
