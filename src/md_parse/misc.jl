const COMMENTS = r"<!--(.|\n)*?-->"
const DEFS = r"@def\s+(\S+)(\s.*)"

"""
    remove_comments(md_string)

Find blocks between `<!--` and `-->` and remove them.
"""
remove_comments(md_string) = replace(md_string, COMMENTS, "")


"""
    extract_page_vars_defs(md_string, var_dict)

Capture lines of the form `@def VARNAME VALUE`. They are then further processed
through `set_vars!` (see `jd_vars.jl`).
"""
function extract_page_vars_defs(md_string)
    # container for recovered definitions
    defs = Pair{String, String}[]
    for m ∈ eachmatch(DEFS, md_string)
        # extract and store recovered definition
        push!(defs, String(m.captures[1])=>String(m.captures[2]))
    end
    md_string = replace(md_string, DEFS, "")
    return (md_string, defs)
end
