"""
    find_md_lxdefs(tokens, blocks, bblocks)

Find `\\newcommand` elements and try to parse what follows to form a proper
Latex command. Return a list of such elements.
The format is:
    \\newcommand{NAMING}[NARG]{DEFINING}
where [NARG] is optional (see `LX_NARG_PAT`).
"""
function find_md_lxdefs(tokens::Vector{Token}, bblocks::Vector{Block})

    lxdefs = Vector{LxDef}()
    active_tokens = ones(Bool, length(tokens))
    # go over tokens, stop over the ones that indicate a newcommand
    for (i, τ) ∈ enumerate(tokens)
        # skip inactive tokens
        active_tokens[i] || continue
        # look for tokens that indicate a newcommand
        (τ.name == :LX_NEWCOMMAND) || continue

        # find first brace blocks after the newcommand (naming)
        fromτ = from(τ)
        k = findfirst(β -> (fromτ < from(β)), bblocks)
        # there must be two brace blocks after the newcommand (name, def)
        if isnothing(k) || !(1 <= k < length(bblocks))
            error("Ill formed newcommand (needs two {...})")
        end

        # try to find a number of arg between these two first {...} to see # if it may contain something which we'll try to interpret as [.d.]
        rge = (to(bblocks[k])+1):(from(bblocks[k+1])-1)
        lxnarg = 0
        # it found something between the naming brace and the def brace
        # check if it looks like [.d.] where d is a number and . are
        # optional spaces (specification of the number of arguments)
        if !isempty(rge)
            lxnarg = match(LX_NARG_PAT, subs(str(bblocks[k]), rge))
            isnothing(lxnarg) && error("Ill formed newcommand (where I
            expected the specification of the number of arguments).")
            matched = lxnarg.captures[2]
            lxnarg = isnothing(matched) ? 0 : parse(Int, matched)
        end

        naming_braces = bblocks[k]
        defining_braces = bblocks[k+1]
        # try to find a valid command name in the first set of braces
        matched = match(LX_NAME_PAT, braces_content(naming_braces))
        isnothing(matched) && error("Invalid definition of a new command expected a command name of the form `\\command`.")
        # keep track of the command name, definition and where it stops
        lxname = matched.captures[1]
        def = braces_content(defining_braces)
        todef = to(defining_braces)
        # store the new latex command
        push!(lxdefs, LxDef(lxname, lxnarg, def, fromτ, todef))

        # mark newcommand token as processed as well as the next token
        # which is necessarily the command name (braces are inactive)
        active_tokens[[i, i+1]] .= false
        # mark any token in the definition as inactive
        deactivate_until = findfirst(τ -> (from(τ) > todef), tokens[i+2:end])
        if isnothing(deactivate_until)
            active_tokens[i+2:end] .= false
        else
            active_tokens[i+2:i+deactivate_until] .= false
        end
    end # tokens
    return lxdefs, tokens[active_tokens]
end


"""
    retrieve_lxdefref(lxname, lxdefs, inmath)

Retrieve the reference pointing to a `LxDef` corresponding to a given `lxname`.
If no reference is found but `inmath=true`, we propagate and let KaTeX deal
with it further down. If something is found, the reference is returned and
will be accessed further down.
"""
function retrieve_lxdefref(lxname::SubString, lxdefs::Vector{LxDef},
                           inmath::Bool=false)

    k = findfirst(δ -> (δ.name == lxname), lxdefs)
    if isnothing(k)
        inmath || error("Command '$lxname' was not defined before it was used.")
        # not found but inmath --> let KaTex deal with it
        return nothing
    end
    (from(lxname) < from(lxdefs[k])) && error("Command '$lxname' was used before it was defined.")
    return Ref(lxdefs, k)
end


"""
    find_md_lxcoms(lxtokens, lxdefs, bblocks, inmath)

Find `\\command{arg1}{arg2}...` outside of `xblocks` and `lxdefs`.
"""
function find_md_lxcoms(tokens::Vector{Token}, lxdefs::Vector{LxDef},
                        bblocks::Vector{Block}, inmath=false)

    lxcoms = Vector{LxCom}()
    active_τ = ones(Bool, length(tokens))
    nbraces = length(bblocks)
    # go over tokens, stop over the ones that indicate a command
    for (i, τ) ∈ enumerate(tokens)
        active_τ[i] || continue
        (τ.name == :LX_COMMAND) || continue
        # get the range of the command
        # > 1. look for the definition given its name
        lxname = τ.ss
        lxdefref = retrieve_lxdefref(lxname, lxdefs, inmath)
        # will only be nothing in a inmath --> no failure, just ignore token
        isnothing(lxdefref) && continue
        # > 1. retrieve narg
        lxnarg = getindex(lxdefref).narg
        # >> there are no arguments
        if lxnarg == 0
            push!(lxcoms, LxCom(lxname, lxdefref))
            active_τ[i] = false
        # >> there is at least one argument
        else
            nextbrace = to(τ) + 1
            b1_idx = findfirst(β -> (from(β) == nextbrace), bblocks)
            # --> it needs to exist + there should be enough left
            if isnothing(b1_idx) || (b1_idx + lxnarg - 1 > nbraces)
                error("Command '$lxname' expects $lxnarg arguments and there should be no spaces between the command name and the first brace: \\com{arg1}... Verify.")
            end
            # --> examine candidate braces, there should be no spaces between
            #  braces to avoid ambiguities
            cand_braces = bblocks[b1_idx:b1_idx+lxnarg-1]
            for bidx ∈ 1:lxnarg-1
                (to(cand_braces[bidx]) + 1 == from(cand_braces[bidx+1])) || error("Argument braces should not be separated by spaces: \\com{arg1}{arg2}... Verify a '$lxname' command.")
            end
            # all good, can push it
            fromcom = from(τ)
            tocom = to(cand_braces[end])
            strcom = subs(str(τ), fromcom, tocom)
            push!(lxcoms, LxCom(strcom, lxdefref, cand_braces))
            # deactivate tokens in the span of the command (will be
            # reparsed later)
            deactivate_until = findfirst(τ->(from(τ)>tocom), tokens[i+1:end])
            if isnothing(deactivate_until)
                active_τ[i+1:end] .= false
            elseif deactivate_until > 1
                active_τ[i+1:i+deactivate_until] .= false
            end
        end
    end
    return lxcoms, tokens[active_τ]
end
