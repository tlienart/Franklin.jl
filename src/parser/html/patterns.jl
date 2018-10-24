"""
    HBLOCK_FUN_PAT

Regex to match `{{ fname param₁ param₂ }}` where `fname` is a html processing
function and `paramᵢ` should refer to appropriate variables in the current
scope.
Available functions are:
    * `{{ fill vname }}`: to plug a variable (e.g.: a date, author name)
    * `{{ insert fpath }}`: to plug in a file referred to by the `fpath` (e.g.: a html header)
"""
const HBLOCK_FUN_PAT = r"{{\s*([a-z]\S+)\s+((.|\n)+?)}}"


"""
    HBLOCK_IF

Regex to match `{{ if vname }}` where `vname` should refer to a boolean in
the current scope.
"""
const HBLOCK_IF_PAT     = r"{{\s*if\s+([a-zA-Z]\S+)\s*}}"
const HBLOCK_ELSE_PAT   = r"{{\s*else\s*}}"
const HBLOCK_ELSEIF_PAT = r"{{\s*else\s*if\s+([a-zA-Z]\S+)\s*}}"
const HBLOCK_END_PAT    = r"{{\s*end\s*}}"
const HBLOCK_IFDEF_PAT  = r"{{\s*ifdef\s+([a-zA-Z]\S+)\s*}}"
const HBLOCK_IFNDEF_PAT = r"{{\s*ifndef\s+([a-zA-Z]\S+)\s*}}"

# If vname else ...

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

# conditional block

struct HCond <: AbstractBlock
    ss::SubString               # full block
    init_cond::String           # initial condition (has to exist)
    sec_conds::Vector{String}   # secondary conditions (can be empty)
    actions::Vector{SubString}  # what to do when conditions are met
end

# If is defined or undefined

struct HIfDef <: AbstractBlock
    ss::SubString
    vname::String
end

struct HIfNDef <: AbstractBlock
    ss::SubString
    vname::String
end

struct HCondDef <: AbstractBlock
    ss::SubString       # full block
    checkisdef::Bool    # true if @isdefined, false if !@isdefined
    vname::String       # initial condition (has to exist)
    action::SubString   # what to do when condition is met
end
HCondDef(β::HIfDef, ss, action) = HCondDef(ss, true, β.vname, action)
HCondDef(β::HIfNDef, ss, action) = HCondDef(ss, false, β.vname, action)

# Function block

struct HFun <: AbstractBlock
    ss::SubString
    fname::String
    params::Vector{String}
end
