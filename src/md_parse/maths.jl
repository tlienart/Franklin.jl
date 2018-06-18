# Asymetric math blocks
const ASYM_MATH = [
    MDBlock((r"\\\[".pattern, r"\\\]".pattern), ("\\[", "\\]")),
    MDBlock((r"\\begin{align}".pattern, r"\\end{align}".pattern),
            ("\$\$\n\\begin{aligned}", "\\end{aligned}\n\$\$")),
    MDBlock((r"\\begin{eqnarray}".pattern, r"\\end{eqnarray}".pattern),
            ("\$\$\n\\begin{array}{c}", "\\end{array}\n\$\$"))
    ]
# Corresponding placeholder
const ASYM_MATH_PH = "##ASYM_MATH_BLOCK##"

# Symetric math blocks
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
