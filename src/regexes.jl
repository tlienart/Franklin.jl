#= =====================================================
LINK patterns, see html link fixer
===================================================== =#
# here we're looking for [id] or [id][] or [stuff][id] or ![stuff][id] but not [id]:
# 1 > (&#33;)? == either ! or nothing
# 2 > &#91;(.*?)&#93; == [...] inside of the brackets
# 3 > (?:&#91;(.*?)&#93;)? == [...] inside of second brackets if there is such
const ESC_LINK_PAT = r"(&#33;)?&#91;(.*?)&#93;(?!:)(?:&#91;(.*?)&#93;)?"

#= =====================================================
HBLOCK patterns, see html blocks
NOTE: the &#123 is { and 125 is }, this is because
Markdown.html converts { => html entity but we want to
recognise those double as {{ so that they can be used
within markdown as well.
NOTE: the for block needs verification (matching parens)
===================================================== =#
const HBO = raw"(?:{{|&#123;&#123;)\s*"
const HBC = raw"\s*(?:}}|&#125;&#125;)"
const VAR = raw"([a-zA-Z_]\S*)"
const ANY = raw"((.|\n)+?)"

const HBLOCK_IF_PAT     = Regex(HBO * raw"if\s+" * VAR * HBC)
const HBLOCK_ELSE_PAT   = Regex(HBO * "else" * HBC)
const HBLOCK_ELSEIF_PAT = Regex(HBO * raw"else\s*if\s+" * VAR * HBC)
const HBLOCK_END_PAT    = Regex(HBO * "end" * HBC)

const HBLOCK_ISDEF_PAT    = Regex(HBO * raw"i(?:s|f)def\s+" * VAR * HBC)
const HBLOCK_ISNOTDEF_PAT = Regex(HBO * raw"i(?:s|f)n(?:ot)?def\s+" * VAR * HBC)

const HBLOCK_ISPAGE_PAT    = Regex(HBO * raw"ispage\s+" * ANY * HBC)
const HBLOCK_ISNOTPAGE_PAT = Regex(HBO * raw"isnotpage\s+" * ANY * HBC)

"""
    HBLOCK_FOR_PAT

Regex to match `{{ for v in iterate }}` or {{ for (v1, v2) in iterate}} etc
where `iterate` is an iterator
"""
const HBLOCK_FOR_PAT = Regex(
        HBO * raw"for\s+" *
        raw"(\(?(?:\s*[a-zA-Z_][^\r\n\t\f\v,]*,\s*)*[a-zA-Z_]\S*\s*\)?)" *
        raw"\s+in\s+" * VAR * HBC)

"""
HBLOCK_FUN_PAT

Regex to match `{{ fname param₁ param₂ }}` where `fname` is a html processing
function and `paramᵢ` should refer to appropriate variables in the current
scope.
"""
const HBLOCK_FUN_PAT = Regex(HBO * VAR * raw"(\s+((.|\n)*?))?" * HBC)

#= =====================================================
Pattern checkers
===================================================== =#

"""
    check_for_pat(v)

Check that we have something like `{{for v in iterate}}` or
`{for (v1,v2) in iterate}}` but not something with unmached parens.
"""
function check_for_pat(v)
    op = startswith(v, "(")
    cp = endswith(v, ")")
    xor(op, cp) &&
        throw(HTMLBlockError("Unbalanced expression in {{for ...}}"))
    !op && occursin(",", v) &&
        throw(HTMLBlockError("Missing parens in {{for ...}}"))
    return nothing
end
