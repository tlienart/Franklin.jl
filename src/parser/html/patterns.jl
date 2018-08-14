"""
    HBLOCK_FUN

Regex to match `{{ fname param₁ param₂ }}` where `fname` is a html processing
function and `paramᵢ` should refer to appropriate variables in the current
scope.
Available functions are:
    * `{{ fill vname }}`: to plug a variable (e.g.: a date, author name)
    * `{{ insert fpath }}`: to plug in a file referred to by the `fpath` (e.g.: a html header)
"""
const HBLOCK_FUN = r"{{\s*([a-z]\S+)\s+((.|\n)+?)}}"

"""
    HBLOCK_IF

Regex to match `{{ if vname }}` where `vname` should refer to a boolean in
the current scope.
"""
const HBLOCK_IF = r"{{\s*if\s+([a-z]\S+)\s*}}"
const HBLOCK_ELSE = r"{{\s*else\s*}}"
const HBLOCK_ELSE_IF = r"{{\s*else\s+if\s+([a-z]\S+)\s*}}"
const HBLOCK_END = r"{{\s*end\s*}}"
