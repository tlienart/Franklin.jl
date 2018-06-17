"""
    MDBlock

A `MDBlock` object contains the information required to find a specific block in
a markdown string as well as how to replace this block.

* `fpat`: pattern describing how to find the block in the string
* `rpat`: pattern describing how to replace the block

When the opening and closing tokens are symetric, we need to keep track of how
long the token is (`sym_offset`).
"""
struct MDBlock
    fpat::Tuple{String, String} # pattern to find the block
    rpat::Tuple{String, String} # pattern to replace the block
    sym_offset::Int # offset for symmetric patterns (see symmetric handling)
end
# Simplified constructor: default offset is 0 (asymmetric case)
MDBlock(fpat, rpat) = MDBlock(fpat, rpat, 0)

"""
    regex(mdb)

Take a `MDBlock` and return the corresponding regex to find it and match the
content of the block.
"""
regex(mdb::MDBlock) = Regex(mdb.fpat[1] * "((.|\\n)*?)" * mdb.fpat[2])


"""
    mdb(elem)

Allow to use a `MDBlock` instance `mdb` to be used as a function on an element
`elem` to return the corresponding replacement string.
"""
(mdb::MDBlock)(elem) = mdb.rpat[1] * elem * mdb.rpat[2]


#=
    MATHS BLOCKS
=#

# Definition of asymetric math blocks
const ASYM_MATH = [
    MDBlock((r"\\\[".pattern, r"\\\]".pattern), ("\\[", "\\]")),
    MDBlock((r"\\begin{align}".pattern, r"\\end{align}".pattern),
            ("\$\$\n\\begin{aligned}", "\\end{aligned}\n\$\$")),
    MDBlock((r"\\begin{eqnarray}".pattern, r"\\end{eqnarray}".pattern),
            ("\$\$\n\\begin{array}{c}", "\\end{array}\n\$\$"))
    ]
# Corresponding placeholder
const ASYM_MATH_PH = "##ASYM_MATH_BLOCK##"

# Definition of symetric math blocks
const SYM_MATH = [
    MDBlock((r"\$\$".pattern, r"\$\$".pattern),
            ("\$\$", "\$\$"), length("\$\$")),
    MDBlock((r"\$".pattern, r"\$".pattern),
            ("\\(", "\\)"), length("\$"))
    ]
# Corresponding placeholder
const SYM_MATH_PH = "##SYM_MATH_BLOCK##"


"""
    extract_asym_math_blocks(md_string)

Capture asymmetric block maths expressions such as `\\begin{...}...\\end{...}`.
"""
function extract_asym_math_blocks(md_string)
    # container for recovered expressions (bm for "block math")
    asym_mb = Pair{MDBlock, String}[]
    counter = 1
    for bpat ∈ ASYM_MATH
        re = regex(bpat)
        for m ∈ eachmatch(re, md_string)
            # store the content of the block
            push!(asym_mb, bpat=>String(m.captures[1]))
            # replace it by a numbered placeholder
            md_string = replace(md_string, re, ASYM_MATH_PH * "$counter", 1)
            counter += 1
        end
    end
    return (md_string, asym_mb)
end


"""
    extract_sym_math_blocks(md_string)

Capture symmetric block maths expressions such as `\$\$...\$\$`.
(Difference with asym is that the function needs to differentiate between
opening and closing symbol).
"""
function extract_sym_math_blocks(md_string)
    # container for recovered expressions (bm for "block math")
    sym_mb = Pair{MDBlock, String}[]
    counter = 1
    for bpat ∈ SYM_MATH
        re = regex(bpat)
        has_pat = true
        while has_pat
            rge_pat = search(md_string, re)
            has_pat = !isempty(rge_pat)
            if has_pat
                # extract and store the content of the block
                off = bpat.sym_offset
                inner = md_string[rge_pat][(1+off):(end-off)]
                push!(sym_mb, bpat=>inner)
                # replace it by a numbered placeholder
                pre, post = rge_pat.start-1, rge_pat.stop+1
                tmp = SYM_MATH_PH * "$counter"
                md_string = md_string[1:pre] * tmp * md_string[post:end]
                counter += 1
            end
        end
    end
    return (md_string, sym_mb)
end


#=
    COMMENTS AND PAGE VARIABLES DEFINITIONS
=#

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
