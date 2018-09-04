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
const HBLOCK_IF     = r"{{\s*if\s+([a-z]\S+)\s*}}"
const HBLOCK_ELSE   = r"{{\s*else\s*}}"
const HBLOCK_ELSEIF = r"{{\s*else\s*if\s+([a-z]\S+)\s*}}"
const HBLOCK_END    = r"{{\s*end\s*}}"


struct HIf <: AbstractBlock
    ss::SubString      # block {{ if vname }}
    vname::String
end

struct HElse <: AbstractBlock
    ss::SubString
end

struct HElseIf <: AbstractBlock
    ss::SubString
    vname::String
end

struct HEnd <: AbstractBlock
    ss::SubString
end

struct HCond <: AbstractBlock
    ss::SubString               # full block
    init_cond::String           # initial condition (has to exist)
    sec_conds::Vector{String}   # secondary conditions (can be empty)
    actions::Vector{SubString}  # what to do when conditions are met
end

struct HFun <: AbstractBlock
    ss::SubString
    fname::String
    params::Vector{String}
end
