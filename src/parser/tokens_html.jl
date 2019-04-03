"""
    HTML_1C_TOKENS

Dictionary of single-char tokens for HTML. Note that these characters are
exclusive, they cannot appear again in a larger token.
"""
const HTML_1C_TOKENS = Dict{Char, Symbol}()


"""
    HTML_TOKENS

Dictionary of tokens for HTML. Note that for each, there may be several possibilities to consider
in which case the order is important: the first case that works will be taken.
"""
const HTML_TOKENS = Dict{Char, Vector{TokenFinder}}(
    '<' => [ isexactly("<!--") => :COMMENT_OPEN  ],  # <!-- ...
    '-' => [ isexactly("-->")  => :COMMENT_CLOSE ],  #      ... -->
    '{' => [ isexactly("{{")   => :H_BLOCK_OPEN  ],  # {{
    '}' => [ isexactly("}}")   => :H_BLOCK_CLOSE ],  # }}
    ) # end dict


const HTML_OCB = [
    # name        opening token    closing token     nestable
    # ------------------------------------------------------------
    :COMMENT => ((:COMMENT_OPEN => :COMMENT_CLOSE), false),
    :H_BLOCK => ((:H_BLOCK_OPEN => :H_BLOCK_CLOSE), true)
    ]

#= ===============
CONDITIONAL BLOCKS
================== =#

#= NOTE / TODO
* in a conditional block, should make sure else is not followed by elseif
* no nesting of conditional blocks is allowed at the moment. This could
be done at later stage (needs balancing) or something but seems a bit overkill
at this point. This second point might fix the first one by making sure that
    HIf -> HElseIf / HElse / HEnd
    HElseIf -> HElseIf / HElse / HEnd
    HElse -> HEnd
=#

"""
    HBLOCK_IF

Regex to match `{{ if vname }}` where `vname` should refer to a boolean in the current scope.
"""
const HBLOCK_IF_PAT        = r"{{\s*if\s+([a-zA-Z]\S+)\s*}}"        # {{if v1}}
const HBLOCK_ELSE_PAT      = r"{{\s*else\s*}}"                      # {{else}}
const HBLOCK_ELSEIF_PAT    = r"{{\s*else\s*if\s+([a-zA-Z]\S+)\s*}}" # {{elseif v1}}
const HBLOCK_END_PAT       = r"{{\s*end\s*}}"                       # {{end}}
const HBLOCK_ISDEF_PAT     = r"{{\s*isdef\s+([a-zA-Z]\S+)\s*}}"     # {{isdef v1}}
const HBLOCK_ISNOTDEF_PAT  = r"{{\s*isnotdef\s+([a-zA-Z]\S+)\s*}}"  # {{isnotdef v1}}
const HBLOCK_ISPAGE_PAT    = r"{{\s*ispage\s+((.|\n)+?)}}"          # {{ispage p1 p2}}
const HBLOCK_ISNOTPAGE_PAT = r"{{\s*isnotpage\s+((.|\n)+?)}}"       # {{isnotpage p1 p2}}

struct HIf <: AbstractBlock
    ss::SubString
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

# -----------------------------------------------------
# General conditional block based on a boolean variable
# -----------------------------------------------------

struct HCond <: AbstractBlock
    ss::SubString               # full block
    init_cond::String           # initial condition (has to exist)
    sec_conds::Vector{String}   # secondary conditions (can be empty)
    actions::Vector{SubString}  # what to do when conditions are met
end

# ------------------------------------------------------------
# Specific conditional block based on whether a var is defined
# ------------------------------------------------------------

struct HIsDef <: AbstractBlock
    ss::SubString
    vname::String
end

struct HIsNotDef <: AbstractBlock
    ss::SubString
    vname::String
end

struct HCondDef <: AbstractBlock
    ss::SubString       # full block
    checkisdef::Bool    # true if @isdefined, false if !@isdefined
    vname::String       # initial condition (has to exist)
    action::SubString   # what to do when condition is met
end
HCondDef(β::HIsDef, ss, action) = HCondDef(ss, true, β.vname, action)
HCondDef(β::HIsNotDef, ss, action) = HCondDef(ss, false, β.vname, action)

# ------------------------------------------------------------
# Specific conditional block based on whether the current page
# is or isn't in a group of given pages
# ------------------------------------------------------------

struct HIsPage <: AbstractBlock
    ss::SubString
    pages::Vector{<:AbstractString} # one or several pages
end

struct HIsNotPage <: AbstractBlock
    ss::SubString
    pages::Vector{<:AbstractString}
end

struct HCondPage <: AbstractBlock
    ss::SubString                    # full block
    checkispage::Bool                # true for ispage false for isnotpage
    pages::Vector{<:AbstractString}  # page names
    action::SubString                # what to do when condition is met
end
HCondPage(β::HIsPage, ss, action) = HCondPage(ss, true, β.pages, action)
HCondPage(β::HIsNotPage, ss, action) = HCondPage(ss, false, β.pages, action)

#= ============
FUNCTION BLOCKS
=============== =#

"""
    HBLOCK_FUN_PAT

Regex to match `{{ fname param₁ param₂ }}` where `fname` is a html processing function and `paramᵢ`
should refer to appropriate variables in the current scope.

Available functions are:
    * `{{ fill vname }}`: to plug a variable (e.g.: a date, author name)
    * `{{ insert fpath }}`: to plug in a file referred to by the `fpath` (e.g.: a html header)
"""
const HBLOCK_FUN_PAT = r"{{\s*([a-z]\S+)\s+((.|\n)+?)}}"


struct HFun <: AbstractBlock
    ss::SubString
    fname::String
    params::Vector{String}
end
