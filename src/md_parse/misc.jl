const COMMENTS = r"<!--(.|\n)*?-->"
const DEFS = r"@def\s+(\S+)(\s.*)"
const ESCAPED = r"(\n|^)~~~\n((.|\n)*?)\n~~~(\n|$)"
const ESCAPED_PH = "##ESCAPED_BLOCK##"

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


"""
    extract_escaped_blocks(md_string)

Capture escaped blocks (surrounded by `~~~`).
"""
function extract_escaped_blocks(md_string)
    eb = String[]
    counter = 1
    for m ∈ eachmatch(ESCAPED, md_string)
        push!(eb, m.captures[2])
        md_string = replace(md_string, ESCAPED, "\n$ESCAPED_PH$counter\n", 1)
        counter += 1
    end
    return (md_string, eb)
end
