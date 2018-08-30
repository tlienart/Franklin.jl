"""
    MD_DEF_PAT

Regex to match an assignment of the form
    @def var = value
The first group captures the name (`var`), the second the assignment (`value`).
"""
const MD_DEF_PAT = r"@def\s+(\S+)\s*?=\s*?(\S.*)"
