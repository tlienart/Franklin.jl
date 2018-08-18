"""
    MD_DEF_PAT

Regex to match an assignment of the form
    @def var = value
The first group captures the name (`var`), the second the assignment (`value`).
"""
const MD_DEF_PAT = r"@def\s+(\S+)\s*?=\s*?(\S.*)"


const DIV_OPEN = r"@@([a-zA-Z]\S*)"
const DIV_CLOSE = r"@@(?![a-zA-Z])"

div_replace_open(hs) = replace(hs, DIV_OPEN => s"<div class=\"\1\">")
div_replace_close(hs) = replace(hs, DIV_CLOSE => "</div>")
div_replace = div_replace_close ∘ div_replace_open
