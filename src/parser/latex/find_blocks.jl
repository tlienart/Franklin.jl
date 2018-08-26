"""
    find_md_lxdefs(str, tokens, blocks, bblocks)

Find `\\newcommand` elements and try to parse what follows to form a proper
Latex command. Return a list of such elements.
The format is:
    \\newcommand{NAMING}[NARG]{DEFINING}
where [NARG] is optional (see `LX_NARG_PAT`).
"""
function find_md_lxdefs(str::String, tokens::Vector{Token},
                         bblocks::Vector{Block})

    lxdefs = Vector{LxDef}()
    active_tokens = ones(Bool, length(tokens))

    for (i, τ) ∈ enumerate(tokens)
        # skip inactive tokens
        active_tokens[i] || continue
        # look for tokens that indicate a newcommand
        (τ.name == :LX_NEWCOMMAND) || continue

        # find first brace blocks after the newcommand (naming)
        k = findfirst(b->(τ.from < b.from), bblocks)
        # there must be two brace blocks after the newcommand (name, def)
        if (k == nothing) || !(1 <= k < length(bblocks))
            error("Ill formed newcommand (needs two {...})")
        end

        # try to find a number of arg between these two first {...} to see # if it may contain something which we'll try to interpret as [.d.]
        rge = (bblocks[k].to+1):(bblocks[k+1].from-1)
        lxnarg = 0
        # it found something between the naming brace and the def brace
        # check if it looks like [.d.] where d is a number and . are
        # optional spaces (specification of the number of arguments)
        if !isempty(rge)
            lxnarg = match(LX_NARG_PAT, str[rge])
            (lxnarg == nothing) && error("Ill formed newcommand (where I
            expected the specification of the number of arguments).")
            tmp = lxnarg.captures[2]
            lxnarg = (tmp == nothing) ? 0 : parse(Int, tmp)
        end

        # η is the range corresponding to the naming braces
        η = brange(bblocks[k])
        # try to find a valid command name in there
        m = match(LX_NAME_PAT, str[η])
        (m == nothing) && error("Invalid definition of a new command expected a command name of the form `\\command`.")
        # keep track of the command name
        lxname = m.captures[1]
        # δ is the range corresponding to the inside of the defining braces
        δ = brange(bblocks[k+1])
        # store the new latex command
        push!(lxdefs, LxDef(lxname, lxnarg, str[δ], τ.from, δ.stop+1))

        # mark newcommand token as processed as well as the next token
        # which is necessarily the command name (braces are inactive)
        active_tokens[[i, i+1]] .= false
        # mark any token in the definition as inactive
        deactivate_until = findfirst(τ->(τ.from > δ.stop+1), tokens[i+2:end])
        if deactivate_until == nothing
            active_tokens[i+2:end] = false
        else
            active_tokens[i+2:i+deactivate_until] .= false
        end
    end # tokens
    return lxdefs, tokens[active_tokens]
end


"""
    find_md_lxcoms(lxtokens, lxdefs, bblocks)

Find `\\command{arg1}{arg2}...` outside of `xblocks` and `lxdefs`.
"""
function find_md_lxcoms(str::String, tokens::Vector{Token},
                        lxdefs::Vector{LxDef}, bblocks::Vector{Block})

    lxcoms = Vector{Block}()
    active_τ = ones(Bool, length(tokens))
    nbraces = length(bblocks)

    for (i, τ) ∈ enumerate(tokens)
        active_τ[i] || continue
        (τ.name == :LX_COMMAND) || continue
        # get the range of the command
        # > 1. look for the definition given its name
        lxname = str[τ.from:τ.to]
        k = findfirst(δ -> (δ.name == lxname), lxdefs)

        # couldn't find the definition or definition was not early enough
        if ((k == nothing) || τ.from < lxdefs[k].from)
            # command is not found
            error("Command '$lxname' was not defined before it was used. Verify.")
        end
        # there is a definition
        # > 1. retrieve narg
        lxnarg = lxdefs[k].narg
        # >> there are no arguments
        if lxnarg == 0
            push!(lxcoms, Block(:LX_COM_NOARG, τ.from, τ.to))
            active_τ[i] = false
        # >> there is at least one argument
        else
            b1_idx = findfirst(b -> (b.from == τ.to + 1), bblocks)
            # --> it needs to exist + there should be enough left
            if (b1_idx == nothing) || (b1_idx + lxnarg - 1 > nbraces)
                error("Command '$lxname' expects $lxnarg arguments and there should be no spaces between the command name and the first brace: \\com{arg1}... Verify.")
            end
            # --> retrieve the candidate braces
            cand_braces = bblocks[b1_idx:b1_idx+lxnarg-1]
            # --> there should be no spaces between braces to avoid ambiguities
            for bidx ∈ 1:lxnarg-1
                (cand_braces[bidx].to+1 == cand_braces[bidx+1].from) || error("Argument braces should not be separated by spaces: \\com{arg1}{arg2}... Verify a '$lxname' command.")
            end
            # all good, can mark it
            com_end = cand_braces[end].to
            push!(lxcoms, Block(:LX_COM_WARGS, τ.from, com_end))
            # deactivate tokens in the span of the command (will be
            # reparsed later)
            deactivate_until = findfirst(τ -> (τ.from > com_end),
                                                tokens[i+1:end])
            if deactivate_until == nothing
                active_τ[i+1:end] .= false
            elseif deactivate_until > 1
                active_τ[i+1:i+deactivate_until] .= false
            end
        end
    end
    return lxcoms, tokens[active_τ]
end
