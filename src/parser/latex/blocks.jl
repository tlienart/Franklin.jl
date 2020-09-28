"""
$(SIGNATURES)

Find `\\newcommand` elements and try to parse what follows to form a proper
Latex command. Return a list of such elements.

The format is:

    \\newcommand{NAMING}[NARG]{DEFINING}

where [NARG] is optional (see `LX_NARG_PAT`).
"""
function find_lxdefs(tokens::Vector{Token}, blocks::Vector{OCBlock})
    # container for the definitions
    lxdefs  = Vector{LxDef}()
    # find braces `{` and `}`
    braces  = filter(β -> β.name == :LXB, blocks)
    nbraces = length(braces)
    # keep track of active tokens
    active_tokens = ones(Bool, length(tokens))
    active_blocks = ones(Bool, length(blocks))

    # go over active tokens, stop over the ones that indicate a newcommand
    # deactivate the tokens that are within the scope of a newcommand
    for (i, τ) ∈ enumerate(tokens)
        # skip inactive tokens
        active_tokens[i] || continue
        # look for tokens that indicate a newcommand
        (τ.name == :LX_NEWCOMMAND) || continue

        # find first brace blocks after the newcommand (naming)
        fromτ = from(τ)
        k = findfirst(β -> (fromτ < from(β)), braces)
        # there must be two brace blocks after the newcommand (name, def)
        if isnothing(k) || !(1 <= k < nbraces)
            throw(LxDefError("Ill formed newcommand (needs two {...})"))
        end

        # try to find a number of arg between these two first {...} to see
        # if it may contain something which we'll try to interpret as [.d.]
        rge    = (to(braces[k])+1):(from(braces[k+1])-1)
        lxnarg = 0
        # it found something between the naming brace and the def brace
        # check if it looks like [.d.] where d is a number and . are
        # optional spaces (specification of the number of arguments)
        if !isempty(rge)
            inter  = subs(str(braces[k]), rge)
            lxnarg = match(LX_NARG_PAT, inter)
            # see test/utils/errors for examples
            if isnothing(lxnarg.captures[1])
                sinner = strip(inter)
                if !isempty(sinner)
                    # corner case: {...}[ ]{...} (empty)
                    if isnothing(match(r"\[\s*\]", sinner))
                        throw(LxDefError(
                            "Ill formed newcommand (where I expected the " *
                            "specification of the number of arguments)."))
                    end
                end
            end
            matched = lxnarg.captures[2]
            lxnarg  = isnothing(matched) ? 0 : parse(Int, matched)
        end

        # assign naming / def
        naming_braces  = braces[k]
        defining_braces = braces[k+1]
        # try to find a valid command name in the first set of braces
        matched = match(LX_NAME_PAT, content(naming_braces))
        if isnothing(matched)
            throw(LxDefError("Invalid definition of a new command expected " *
                             "a command name of the form `\\command`."))
        end

        # keep track of the command name, definition and where it stops
        lxname = matched.captures[1]
        lxdef  = stent(defining_braces)
        todef  = to(defining_braces)
        # store the new latex command
        push!(lxdefs, LxDef(lxname, lxnarg, lxdef, fromτ, todef))

        # mark newcommand token as processed as well as the next token
        # which is necessarily the command name (brace token is inactive here)
        active_tokens[i] = false
        # mark any block (inc. braces!) starting in the scope as inactive
        for (i, isactive) ∈ enumerate(active_blocks)
            isactive || continue
            (fromτ ≤ from(blocks[i]) ≤ todef) && (active_blocks[i] = false)
        end
    end # of enumeration of tokens

    # filter out the stuff that's now marked as inactive by virtue of being
    # part of a newcommand definition (these things will be inspected later)
    tokens = tokens[active_tokens]
    blocks = blocks[active_blocks]
    # separate the braces from the rest of the blocks, they will be used
    # to define the lxcoms
    braces_mask = map(β -> β.name == :LXB, blocks)
    braces = blocks[braces_mask]
    blocks = blocks[@. ~braces_mask]

    return lxdefs, tokens, braces, blocks
end


"""
$(SIGNATURES)

Get the reference pointing to a `LxDef` corresponding to a given `lxname`.
If no reference is found but `inmath=true`, we propagate and let KaTeX deal
with it. If something is found, the reference is returned and will be accessed
further down.
"""
function get_lxdef_ref(lxname::SubString, lxdefs::Vector{LxDef},
                       inmath::Bool=false, offset::Int=0)::Ref
    # find lxdefs with matching name
    ks = findall(δ -> (δ.name == lxname), lxdefs)
    # check that the def is before the usage
    fromlx = from(lxname) + offset
    filter!(k -> (fromlx > from(lxdefs[k])), ks)
    if isempty(ks)
        if isdefined(Main, :Utils) && isdefined(Main.Utils, Symbol("lx_$(lxname[2:end])"))
            return Ref(nothing)
        elseif !inmath
            throw(LxComError("Command '$lxname' was used before it was defined."))
        end
        # not found but inmath --> let KaTex deal with it
        return Ref(nothing)
    end
    return Ref(lxdefs, ks[end])
end


"""
$(SIGNATURES)

Find `\\command{arg1}{arg2}...` outside of `xblocks` and `lxdefs`.
"""
function find_lxcoms(tokens::Vector{Token}, lxdefs::Vector{LxDef},
                     braces::Vector{OCBlock}, offset::Int=0;
                     inmath::Bool=false)::Tuple{Vector{LxCom},Vector{Token}}
    # containers for the lxcoms
    lxcoms   = Vector{LxCom}()
    active_τ = ones(Bool, length(tokens))
    nbraces  = length(braces)

    # go over tokens, stop over the ones that indicate a command
    for (i, τ) ∈ enumerate(tokens)
        active_τ[i] || continue
        τ.name == :LX_COMMAND || continue
        # 1. look for the definition given the command name
        lxname   = τ.ss
        lxdefref = get_lxdef_ref(lxname, lxdefs, inmath, offset)
        derived  = false
        # will only be nothing in a 'inmath' --> no failure, just ignore token
        if isnothing(lxdefref[])
            lxn = lxname[2:end]
            fun = Symbol("lx_" * lxn)
            if isdefined(Main, :Utils) && isdefined(Main.Utils, fun)
                # take a single bracket
                lxnarg  = 1
                derived = true
            else
                continue
            end
        else
            lxnarg = getindex(lxdefref).narg
        end
        # 2. explore with # arguments
        # 2.a there are none
        if lxnarg == 0
            push!(lxcoms, LxCom(lxname, lxdefref))
            active_τ[i] = false

        # >> there is at least one argument --> find all of them
        else
            # spot where an opening brace is expected
            nxtidx = to(τ) + 1
            b1_idx = findfirst(β -> (from(β) == nxtidx), braces)
            # --> it needs to exist + there should be enough braces left
            if isnothing(b1_idx) || (b1_idx + lxnarg - 1 > nbraces)
                throw(LxComError("""
                    Command '$lxname' expects $lxnarg argument(s) and there
                    should be no space(s) between the command name and the first
                    brace: \\com{arg1}...
                    """))
            end

            # --> examine candidate braces, there should be no spaces between
            #  braces to avoid ambiguities
            cand_braces = braces[b1_idx:b1_idx+lxnarg-1]
            for bidx ∈ 1:lxnarg-1
                if (to(cand_braces[bidx]) + 1 != from(cand_braces[bidx+1]))
                    throw(LxComError("""
                        Argument braces should not be separated by space(s):
                        \\com{arg1}{arg2}... Verify a '$lxname' command.
                        """))
                end
            end

            # all good, can push it
            from_c = from(τ)
            to_c   = to(cand_braces[end])
            str_c  = subs(str(τ), from_c, to_c)
            if derived
                push!(lxcoms, LxCom(str_c, nothing, cand_braces))
            else
                push!(lxcoms, LxCom(str_c, lxdefref, cand_braces))
            end

            # deactivate tokens in the span of the command (will be
            # reparsed later)
            first_active = findfirst(τ -> (from(τ) > to_c), tokens[i+1:end])
            if isnothing(first_active)
                active_τ[i+1:end] .= false
            elseif first_active > 1
                active_τ[i+1:(i+first_active-1)] .= false
            end
        end
    end
    return lxcoms, tokens[active_τ]
end


"""
$(SIGNATURES)

Find `\\begin{xxx}` and `\\end{xxx}` blocks.
"""
function form_lxenv_delims!(tokens::Vector{Token}, blocks::Vector{OCBlock})
    rmidx = Int[]
    for (i, τ) ∈ enumerate(tokens)
        τ.name ∈ (:CAND_LX_BEGIN, :CAND_LX_END) || continue
        # try to get an adjoining brace
        nxtidx = to(τ) + 1
        braceidx = findfirst(β, (β.name == :LXB && from(β) == nxtidx), blocks)
        # it needs to exist
        if isnothing(braceidx)
            throw(LxEnvError("""
                Found a delimiter '\\begin' or '\\end' and expected a name in braces
                after that but didn't find it. There should be no space between the
                delimiter and the brace: \\begin{name}.
                """))
        end
        push!(rmidx, braceidx)
        # get the brace
        brace = blocks[braceidx]
        # form a valid token and replace the candidate by it
        from_c = from(τ)
        to_c = to(brace)
        name = ifelse(τ.name == :CAND_LX_BEGIN, :LX_BEGIN, :LX_END)
        tokens[i] = Token(name, subs(τ.ss.string, from_c, to_c))
    end
    deleteat!(blocks, rmidx)
    return nothing
end


function form_lxenvs(delims::Vector{Token})
    # they are ordered

    # TODO

    # -- pair off the LX_BEGIN and matching LX_END
    # -- allow definition of NEWENVIRONMENT
    # -- test the whole lot
    # -- write a convert ocb which takes the content, puts it between the stuff then
    # reprocesses the lot.
    # -- re-add the math envs.


end


## List of Changes
# converter/markdown/md.jl L76 -- 82
# parser/latex/blocks --> function at L230
# parser/markdown/tokens --> commented out maths envs in MD_TOKENS, MD_OCB_MATH
# utils/errors added LxEnvError L29
# regexes added \* to the LX_NAME_PAT + also extended the tests
