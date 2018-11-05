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

###############################################################################

"""
    qualify_html_hblocks(blocks)

Given `{{ ... }}` blocks, identify what blocks they are and return a vector
of qualified blocks of type `AbstractBlock`.
"""
function qualify_html_hblocks(blocks::Vector{OCBlock})

    qb = Vector{AbstractBlock}(undef, length(blocks))
    for (i, β) ∈ enumerate(blocks)
        # if block {{ if v }}
        m = match(HBLOCK_IF_PAT, β.ss)
        isnothing(m) ||
            (qb[i] = HIf(β.ss, m.captures[1]); continue)
        # else block {{ else }}
        m = match(HBLOCK_ELSE_PAT, β.ss)
        isnothing(m) ||
            (qb[i] = HElse(β.ss); continue)
        # else if block {{ elseif v }}
        m = match(HBLOCK_ELSEIF_PAT, β.ss)
        isnothing(m) ||
            (qb[i] = HElseIf(β.ss, m.captures[1]); continue)
        # end block {{ end }}
        m = match(HBLOCK_END_PAT, β.ss)
        isnothing(m) ||
            (qb[i] = HEnd(β.ss); continue)
        # ifdef block
        m = match(HBLOCK_IFDEF_PAT, β.ss)
        isnothing(m) ||
            (qb[i] = HIfDef(β.ss, m.captures[1]); continue)
        # ifndef block
        m = match(HBLOCK_IFNDEF_PAT, β.ss)
        isnothing(m) ||
            (qb[i] = HIfNDef(β.ss, m.captures[1]); continue)
        # function block {{ fname v1 v2 ... }}
        m = match(HBLOCK_FUN_PAT, β.ss)
        isnothing(m) ||
            (qb[i] = HFun(β.ss, m.captures[1], split(m.captures[2])); continue)
        error("I found a HBlock that did not match anything, verify '$ts'")
    end
    return qb
end


"""
    find_html_cblocks(qblocks)

Given qualified blocks `HIf`, `HElse` etc, construct a vector of the
conditional blocks which contain the list of conditions etc.
No nesting is allowed at the moment.
"""
function find_html_cblocks(qblocks::Vector{AbstractBlock})

    cblocks = Vector{HCond}()
    isempty(qblocks) && return cblocks, qblocks
    active_qblocks = ones(Bool, length(qblocks))
    i = 0
    while i < length(qblocks)
        i += 1
        β = qblocks[i]
        (typeof(β) == HIf) || continue

        # look forward until the next `{{ end }}` block
        k = findfirst(cβ -> (typeof(cβ) == HEnd), qblocks[i+1:end])
        isnothing(k) && error("Found an {{ if ... }} block but no matching {{ end }} block. Verify.")
        n_between = k - 1
        k += i

        initial_cond = β.vname
        secondary_conds = Vector{String}()
        afrom, ato = Vector{Int}(), Vector{Int}()
        push!(afrom, to(β) + 1)

        for bi ∈ 1:n_between
            β = qblocks[i + bi]
            if typeof(β) == HElseIf
                push!(ato,   from(β) - 1)
                push!(afrom, to(β) + 1)
                push!(secondary_conds, β.vname)
            elseif typeof(β) == HElse
                # TODO, should check that there are no other HElseIf etc after
                push!(ato,   from(β) - 1)
                push!(afrom, to(β) + 1)
            end
        end
        stβ, endβ = qblocks[i], qblocks[k]
        hcondss = subs(str(stβ), from(stβ), to(endβ))
        push!(ato, from(endβ) - 1)

        # assemble the actions
        actions = [subs(str(stβ), afrom[i], ato[i]) for i ∈ eachindex(afrom)]
        # form the hcond
        push!(cblocks, HCond(hcondss, initial_cond, secondary_conds, actions))
        active_qblocks[i:k] .= false
        i = k
    end
    return cblocks, qblocks[active_qblocks]
end


"""
    find_html_cdblocks(qblocks)

Given qualified blocks `HIfDef` or `HIfNDef` build a conditional def block.
"""
function find_html_cdblocks(qblocks::Vector{AbstractBlock})

    cdblocks = Vector{HCondDef}()
    isempty(qblocks) && return cdblocks, qblocks
    active_qblocks = ones(Bool, length(qblocks))
    i = 0
    while i < length(qblocks)
        i += 1
        β = qblocks[i]
        (typeof(β) ∈ [HIfDef, HIfNDef]) || continue
        # look forward until next `{{end}} block
        k = findfirst(cβ -> (typeof(cβ) == HEnd), qblocks[i+1:end])
        isnothing(k) && error("Found an {{ if(n)def ...}} block but no matching {{end}} block. Verify.")
        k += i
        endβ = qblocks[k]
        hcondss = subs(str(β), from(β), to(endβ))
        action = subs(str(β), to(β)+1, from(endβ)-1)
        push!(cdblocks, HCondDef(β, hcondss, action))
        active_qblocks[i:k] .= false
        i = k
    end
    return cdblocks, qblocks[active_qblocks]
end
