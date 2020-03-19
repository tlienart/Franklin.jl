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
NOTE: the for block needs verification (matching parens)
===================================================== =#

const HBLOCK_IF_PAT        = r"{{\s*if\s+([a-zA-Z_]\S*)\s*}}"
const HBLOCK_ELSE_PAT      = r"{{\s*else\s*}}"
const HBLOCK_ELSEIF_PAT    = r"{{\s*else\s*if\s+([a-zA-Z_]\S*)\s*}}"
const HBLOCK_END_PAT       = r"{{\s*end\s*}}"

const HBLOCK_ISDEF_PAT     = r"{{\s*i(?:s|f)def\s+([a-zA-Z_]\S*)\s*}}"
const HBLOCK_ISNOTDEF_PAT  = r"{{\s*i(?:s|f)n(?:ot)?def\s+([a-zA-Z_]\S*)\s*}}"
const HBLOCK_ISPAGE_PAT    = r"{{\s*ispage\s+((.|\n)+?)}}"
const HBLOCK_ISNOTPAGE_PAT = r"{{\s*isnotpage\s+((.|\n)+?)}}"

const HBLOCK_FOR_PAT = r"{{\s*for\s+(\(?(?:\s*[a-zA-Z_][^\r\n\t\f\v,]*,\s*)*[a-zA-Z_]\S*\s*\)?)\s+in\s+([a-zA-Z_]\S*)\s*}}"

const HBLOCK_TOC_PAT = r"{{\s*toc\s*}}"
