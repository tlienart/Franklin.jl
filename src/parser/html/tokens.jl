"""
HTML_1C_TOKENS

Dictionary of single-char tokens for HTML. Note that these characters are
exclusive, they cannot appear again in a larger token.
"""
const HTML_1C_TOKENS = LittleDict{Char, Symbol}()


"""
HTML_TOKENS

Dictionary of tokens for HTML. Note that for each, there may be several
possibilities to consider in which case the order is important: the first case
that works will be taken.
"""
const HTML_TOKENS = LittleDict{Char, Vector{TokenFinder}}(
    '<' => [ isexactly("<!--") => :COMMENT_OPEN  ],  # <!-- ...
    '-' => [ isexactly("-->")  => :COMMENT_CLOSE ],  #      ... -->
    '{' => [ isexactly("{{")   => :H_BLOCK_OPEN  ],  # {{
    '}' => [ isexactly("}}")   => :H_BLOCK_CLOSE ],  # }}
    ) # end dict


"""
HTML_OCB

List of HTML Open-Close blocks.
"""
const HTML_OCB = [
    # name        opening token    closing token(s)     nestable
    # ----------------------------------------------------------
    OCProto(:COMMENT, :COMMENT_OPEN, (:COMMENT_CLOSE,), false),
    OCProto(:H_BLOCK, :H_BLOCK_OPEN, (:H_BLOCK_CLOSE,), true)
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
$(TYPEDEF)

HTML token corresponding to `{{if var}}`.
"""
struct HIf <: AbstractBlock
    ss::SubString
    vname::String
end

"""
$(TYPEDEF)

HTML token corresponding to `{{else}}`.
"""
struct HElse <: AbstractBlock
    ss::SubString
end

"""
$(TYPEDEF)

HTML token corresponding to `{{elseif var}}`.
"""
struct HElseIf <: AbstractBlock
    ss::SubString
    vname::String
end

"""
$(TYPEDEF)

HTML token corresponding to `{{end}}`.
"""
struct HEnd <: AbstractBlock
    ss::SubString
end

# -----------------------------------------------------
# General conditional block based on a boolean variable
# -----------------------------------------------------

"""
$(TYPEDEF)

HTML conditional block corresponding to `{{if var}} ... {{else}} ... {{end}}`.
"""
struct HCond <: AbstractBlock
    ss::SubString               # full block
    init_cond::String           # initial condition (has to exist)
    sec_conds::Vector{String}   # secondary conditions (can be empty)
    actions::Vector{SubString}  # what to do when conditions are met
end

# ------------------------------------------------------------
# Specific conditional block based on whether a var is defined
# ------------------------------------------------------------

"""
$(TYPEDEF)

HTML token corresponding to `{{isdef var}}`.
"""
struct HIsDef <: AbstractBlock
    ss::SubString
    vname::String
end


"""
$(TYPEDEF)

HTML token corresponding to `{{isnotdef var}}`.
"""
struct HIsNotDef <: AbstractBlock
    ss::SubString
    vname::String
end

# ------------------------------------------------------------
# Specific conditional block based on whether the current page
# is or isn't in a group of given pages
# ------------------------------------------------------------

"""
$(TYPEDEF)

HTML token corresponding to `{{ispage path/page}}`.
"""
struct HIsPage <: AbstractBlock
    ss::SubString
    pages::Vector{<:AS} # one or several pages
end


"""
$(TYPEDEF)

HTML token corresponding to `{{isnotpage path/page}}`.
"""
struct HIsNotPage <: AbstractBlock
    ss::SubString
    pages::Vector{<:AS}
end

"""
$(TYPEDEF)

HTML token corresponding to `{{for x in iterable}}`.
"""
struct HFor <: AbstractBlock
    ss::SubString
    vname::String
    iname::String
end

#= ============
FUNCTION BLOCKS
=============== =#

"""
$(TYPEDEF)

HTML function block corresponding to `{{ fname p1 p2 ...}}`.
"""
struct HFun <: AbstractBlock
    ss::SubString
    fname::String
    params::Vector{String}
end


"""
$(TYPEDEF)

Empty struct to keep the same taxonomy.
"""
struct HToc <: AbstractBlock end
