#=
NOTE if ismaths -> don't fail when unknown command (let KaTeX fail)
=#
"""
    resolve_latex(str, bfrom, bto, ismaths, lxtokens, lxdefs, bblocks)

Consider a string `str` over a specfic range `str[bfrom, bto]` and resolve
any user-defined latex commands that may be in there. The parameter `ismaths`
helps track whether the current context is a math block or not. In a math block
unknown command should not raise an error and be fed to KaTeX which may be able
to deal with them or will raise an error itself. `lxtokens` is a list of tokens
corresponding to latex commands, `lxdefs` is the collection of user definitions
and `lxdefs_locs` keeps track of where (how early) things are defined (commands
cannot be used before they've been defined).
Once the definition of a found command is applied, a re-parsing is necessary
since the definition of the command may itself contain tokens.
The function returns the resulting string once all user-defined commands have
been appropriately replaced and processed.
"""
function resolve_latex(str::String, bfrom::Int, bto::Int, ismaths::Bool,
                       lxtokens::Vector{Token}, lxdefs::Vector{LxDef},
                       bblocks::Vector{Block})

    # filter lxtokens in the given range (bfrom-bto)
    lxtokens_in = filter(τ -> (τ.from >= bfrom) & (τ.to <= bto), lxtokens)
    active_lxt_in = [true for τ ∈ lxtokens_in]

    # no commands? just return the string over the given range
    isempty(lxtokens_in) && return str[bfrom:bto]
    # otherwise, get braces in given range
    braces_in = filter(b -> (b.from >= bfrom) & (b.to <= bto), bblocks)
    nbraces_in = length(braces_in)

    # go over the commands in the block
    offset = bfrom
    pieces = Vector{String}()
    flags = Vector{Bool}()
    for (i, lxtoken) ∈ enumerate(lxtokens_in)
        active_lxt_in[i] || continue
        # store what's before the first command (if there is anything)
        (offset < lxtoken.from) &&
            push!(pieces, md2html(str[offset:lxtoken.from-1], ismaths))
        # get the range of the command
        # 1. look for the definition given its name
        lxname = str[lxtoken.from:lxtoken.to]
        k = findfirst(δ -> (δ.name == lxname), lxdefs)

        if (k == nothing) & ismaths
            #=
            command is not found but it's a math environment, consider as
            potential KaTeX command, greedy take braces til space
            1. add the name to the pieces
            2. add all the braces associated to it after having resolved what's
            in the braces
            =#
            # 1. keep the name on the stack
            push!(pieces, lxname)
            # 2. look for adjoining braces
            cand_braces = Vector{Block}()
            b_idx = findfirst(b -> (b.from == lxtoken.to + 1), braces_in)
            (b_idx == nothing) && (offset = lxtoken.to + 1; continue)
            while b_idx != nothing
                cur_b = braces_in[b_idx]
                push!(cand_braces, cur_b)
                b_idx = findfirst(b -> (b.from == cur_b.to + 1), braces_in)
            end
            # resolve what's inside the braces
            for arg ∈ cand_braces
                push!(pieces, "{" * resolve_latex(str, arg.from+1, arg.to-1,
                        ismaths, lxtokens, lxdefs, bblocks) * "}")
            end
            # move the head to after the command and its braces
            offset = cand_braces[end].to + 1
        else
            # this is potentially a user-defined command => the definition
            # needs to exist and be before the command
            if (k == nothing) || (lxtoken.from < lxdefs[k].from)
                error("Command '$lxname' was not defined before it was used. Verify\n '$(str[bfrom:bto])'")
            end
            # => there is a definition, retrieve narg
            lxnarg = lxdefs[k].narg
            # ==> if zero argument, just plug the definition in.
            if iszero(lxnarg)
                # the def may contain stuff that need to be converted
                partial, _ = convert_md(lxdefs[k].def * EOS, lxdefs,
                                        isconfig=false, has_mddefs=false)
                push!(pieces, partial)
                offset = lxtoken.to + 1
                continue
            end
            # ==> if several arguments, find the first braces
            b1_idx = findfirst(b -> (b.from == lxtoken.to + 1), braces_in)
            # --> it needs to exist + there should be enough left
            if (b1_idx == nothing) || (b1_idx + lxnarg - 1 > nbraces_in)
                error("Command '$lxname' expects $lxnarg arguments and there should be no spaces between command name and first brace: \\com{arg1}... Verify\n '$(str[bfrom:bto])'")
            end
            # --> retrieve the candidate braces
            cand_braces = braces_in[b1_idx:b1_idx+lxnarg-1]
            # --> there should be no spaces between braces to avoid ambiguities
            for bidx ∈ 1:lxnarg-1
                (cand_braces[bidx].to+1 == cand_braces[bidx+1].from) || error("Argument braces should not be separated by spaces: \\com{arg1}{arg2}... Verify\n '$(str[from:to])'")
            end

            # then apply the definition of the command
            partial = lxdefs[k].def
            for (argnum, b) ∈ enumerate(cand_braces)
                partial = replace(partial, "#$argnum", str[b.from+1:b.to-1])
            end

            # re-parsing is necessary to deal with whatever the definition
            # may bring (including commands / tokens)
            # if we're currently in mathmode, we need to keep track of that
            partial = ifelse(ismaths, "_\$>_" *partial* "_\$<_", partial) * EOS
            partial, _ = convert_md(partial, lxdefs,
                                     isconfig=false, has_mddefs=false)
            push!(pieces, partial)

            # now we need to deactivate all tokens that are in the span of
            # the command we just processed, they will have been processed by
            # the re-parsing
            com_end = cand_braces[end].to
            deactivate_until = findfirst(τ -> τ.from > com_end,
                                         lxtokens_in[i+1:end])
            if deactivate_until == nothing
                active_lxt_in[i+1:end] = false
            elseif deactivate_until > 1
                active_lxt_in[i+1:i+deactivate_until] = false
            end
            # move the head to after the command and its braces
            offset = cand_braces[end].to + 1
        end
    end
    # store what's left after the last command (if anything)
    (offset <= bto) &&
        push!(pieces, md2html(str[offset:bto], ismaths))
    # assemble the pieces and return the string
    return prod(pieces)
end
