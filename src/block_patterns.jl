"""
    BlockPat

A BlockPat object contains the information required to find a specific block
in a raw string as well as how to replace this block. The patterns are tuples
containing strings, one to determine how the block starts, the other how it
ends.

- fpat: a pattern describing how to find the block in the original string
- rpat: a pattern describing how to replace the block

Main case is asymetric where the block starts with a tag and ends with another.
In the symetric case, the offset (how long is the tag) is important to be able
to detect the block.
"""
struct BlockPat
    fpat::Tuple{String, String} # pattern to find the block
    rpat::Tuple{String, String} # pattern to replace the block
    sym_offset::Int # offset for symmetric patterns (see symmetric handling)
end


# Simplified constructor: default offset is 0 (asymmetric case)
BlockPat(fpat, rpat) = BlockPat(fpat, rpat, 0)

# Go from a pattern to a regex that can be found
regex(bp::BlockPat) = Regex(bp.fpat[1] * "((.|\\n)*?)" * bp.fpat[2])

# Go from a pattern to a replacement string
(bp::BlockPat)(elem) = bp.rpat[1] * elem * bp.rpat[2]


# Definition of asymetric math blocks + replacement symbols
const ASYM_MATH = [
    BlockPat((r"\\\[".pattern, r"\\\]".pattern), ("\\[", "\\]")),
    BlockPat((r"\\begin{align}".pattern, r"\\end{align}".pattern),
            ("\$\$\n\\begin{aligned}", "\\end{aligned}\n\$\$")),
    BlockPat((r"\\begin{eqnarray}".pattern, r"\\end{eqnarray}".pattern),
            ("\$\$\n\\begin{array}{c}", "\\end{array}\n\$\$"))
    ]
const ASYM_MATH_PH = "##ASYM_MATH_BLOCK##"


# Definition of symetric math blocks + replacement symbols
const SYM_MATH = [
    BlockPat((r"\$\$".pattern, r"\$\$".pattern),
            ("\$\$", "\$\$"), length("\$\$")),
    BlockPat((r"\$".pattern, r"\$".pattern),
            ("\\(", "\\)"), length("\$"))
    ]
const SYM_MATH_PH = "##SYM_MATH_BLOCK##"


# Definition of div block (not a BlockPat because here we allow for the
# block to be named and that named must be captured. This is the first
# capturing group ([a-zA-Z]\S*)
const DIV = r"@@([a-zA-Z]\S*)((.|\n)*?)@@"
const DIV_PH = "##DIV_BLOCK##"


const COMMENTS = r"<!--(.|\n)*?-->"
const DEFS = r"@def\s+(\S+)(\s.*)"
const BRACES_BLOCK = r"{{\s*([a-z]\S+)\s+([^}]*)}}"
