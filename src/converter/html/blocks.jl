"""
$SIGNATURES

Recursively process a conditional block from an opening HTML_COND_OPEN to a
{{end}}.
"""
function process_html_cond(hs::AS, qblocks::Vector{AbstractBlock},
                           i::Int)::Tuple{String,Int,Int}
    if i == length(qblocks)
        throw(HTMLBlockError("Could not close the conditional block " *
                             "starting with '$(qblocks[i].ss)'."))
    end

    init_idx      = i
    else_idx      = 0
    elseif_idx    = Vector{Int}()
    accept_elseif = true # false as soon as we see an else block
    content       = ""

    # inbalance keeps track of whether we've managed to find a
    # matching {{end}}. It increases if it sees other opening {{if..}}
    # and decreases if it sees a {{end}}
    inbalance = 1
    probe = qblocks[i] # just for allocation
    while i < length(qblocks) && inbalance > 0
        i    += 1
        probe = qblocks[i]
        # if we have a {{elseif ...}} or {{else}} with the right level,
        # keep track of them
        if inbalance == 1
            if probe isa HElseIf
                accept_elseif || throw(HTMLBlockError("Saw a {{elseif ...}} " *
                                            "after a {{else}} block."))
                push!(elseif_idx, i)
            elseif probe isa HElse
                else_idx      = i
                accept_elseif = false
            end
        end
        inbalance += hbalance(probe)
    end
    # we've exhausted the candidate qblocks and not found an appropriate {{end}}
    if inbalance > 0
        throw(HTMLBlockError("Could not close the conditional block " *
                             "starting with '$(qblocks[init_idx].ss)'."))
    end

    # we've found the closing {{end}} at index `i`
    β_close = probe
    i_close = i

    # We now have a complete conditional block with possibly
    # several else-if blocks and possibly an else block.
    # Check which one applies and discard the rest

    k   = 0 # index of the first verified condition
    lag = 0 # aux var to distinguish 1st block case

    # initial block may be {{if..}} or {{isdef..}} or...
    # if its not just a {{if...}}, need to act appropriately
    # and if the condition is verified then k=1
    βi = qblocks[init_idx]
    if βi isa Union{HIsDef,HIsNotDef,HIsPage,HIsNotPage}
        lag = 1
        if βi isa HIsDef
            k = Int(haskey(LOCAL_VARS, βi.vname))
        elseif βi isa HIsNotDef
            k = Int(!haskey(LOCAL_VARS, βi.vname))
        else
            # HIsPage//HIsNotPage
            rpath = splitext(unixify(locvar("fd_rpath")))[1]
            if FD_ENV[:STRUCTURE] < v"0.2"
                # current path is relative to /src/ for instance
                # /src/pages/blah.md -> pages/blah
                # if starts with `pages/`, replaces by `pub/`:
                # pages/blah => pub/blah
                rpath = replace(rpath, Regex("^pages") => "pub")
            end
            # compare with β.pages
            inpage = any(p -> match_url(rpath, p), βi.pages)

            if βi isa HIsPage
                k = Int(inpage)
            else
                k = Int(!inpage)
            end
        end
    end

    # If we've not yet found a verified condition, keep looking
    # Now all cond blocks ahead are {{if ...}} {{elseif  ...}}
    if iszero(k)
        if lag == 0
            conds = [βi.vname, (qblocks[c].vname for c in elseif_idx)...]
        else
            conds = [qblocks[c].vname for c in elseif_idx]
        end
        known = [haskey(LOCAL_VARS, c) for c in conds]

        if !all(known)
            idx = findfirst(.!known)
            throw(HTMLBlockError("At least one of the condition variable " *
                                 "could not be found: check '$(conds[idx])'."))
        end
        # check that all these variables are bool
        bools = [isa(locvar(c), Bool) for c  in conds]
        if !all(bools)
            idx = findfirst(.!bools)
            throw(HTMLBlockError("At least one of the condition variable is " *
                                 " not a Bool: check '$(conds[idx])'."))
        end
        # which one is verified?
        u = findfirst(c -> locvar(c), conds)
        k = isnothing(u) ? 0 : u + lag
    end

    if iszero(k)
        # if we still haven't found a verified condition, use the else
        # if there is one
        if !iszero(else_idx)
            # use elseblock, the content is from it to the β_close
            head = nextind(hs, to(qblocks[else_idx]))
            tail = prevind(hs, from(β_close))
            # get the stack of blocks in there
            action_qblocks = qblocks[else_idx+1:i_close-1]
            # process
            content = process_html_qblocks(hs, action_qblocks, head, tail)
        end
    else
        # determine the span of blocks
        oidx = 0 # opening conditional
        cidx = 0 # closing conditional
        if k == 1
            oidx = init_idx
        else
            oidx = elseif_idx[k-1]
        end
        if k ≤ length(elseif_idx)
            cidx = elseif_idx[k]
        else
            cidx = ifelse(iszero(else_idx), i_close, else_idx)
        end
        # Get the content
        head = nextind(hs, to(qblocks[oidx]))
        tail = prevind(hs, from(qblocks[cidx]))
        # Get the stack of blocks in there
        action_qblocks = qblocks[oidx+1:cidx-1]
        # process
        content = process_html_qblocks(hs, action_qblocks, head, tail)
    end
    # move the head after the final {{end}}
    head = nextind(hs, to(β_close))

    return content, head, i_close
end

"""
$SIGNATURES

Process a for block.
"""
function process_html_for(hs::AS, qblocks::Vector{AbstractBlock},
                          i::Int)::Tuple{String,Int,Int}
    # check that the iterable is known
    β_open = qblocks[i]
    vname  = β_open.vname
    iname  = β_open.iname
    if !haskey(LOCAL_VARS, iname)
        throw(HTMLBlockError("The iterable '$iname' is not recognised. " *
                             "Please make sure it's defined."))
    end

    # try to close the for loop
    if i == length(qblocks)
        throw(HTMLBlockError("Could not close the conditional block " *
                             "starting with '$(qblocks[i].ss)'."))
    end

    init_idx = i
    content  = ""

    # inbalance keeps track of whether we've managed to find a
    # matching {{end}}. It increases if it sees other opening {{if..}}
    # and decreases if it sees a {{end}}
    inbalance = 1
    while i < length(qblocks) && inbalance > 0
        i         += 1
        inbalance += hbalance(qblocks[i])
    end
    # we've exhausted the candidate qblocks and not found an appropriate {{end}}
    if inbalance > 0
        throw(HTMLBlockError("Could not close the conditional block " *
                             "starting with '$(qblocks[init_idx].ss)'."))
    end
    # we've found the closing {{end}} and index `i`
    β_close = qblocks[i]
    i_close = i

    isempty(locvar(iname)) && @goto final_step

    # is vname a single variable or multiple variables?
    # --> {{for v in iterate}}
    # --> {{for (v1, v2) in iterate }}
    vnames = [vname]
    if startswith(vname, "(")
        vnames = strip.(split(vname[2:end-1], ","))
    end
    # check that the first element of the iterate has the same length
    el1 = first(locvar(iname))
    length(vnames) in (1, length(el1)) ||
        throw(HTMLBlockError("In a {{for ...}}, the first element of" *
                "the iterate has length $(length(el1)) but tried to unpack" *
                "it as $(length(vnames)) variables."))

    # so now basically we have to simply copy-paste the content replacing
    # variable `vname` when it appears in a html block {{...}}
    # users should try not to be dumb about this... if vname or iname
    # corresponds to something they shouldn't touch, they'll crash things.

    # content of the for block
    inner = subs(hs, nextind(hs, to(β_open)), prevind(hs, from(β_close)))
    isempty(strip(inner)) && @goto final_step
    content = ""
    if length(vnames) == 1
        for value in locvar(iname)
            # at the moment we only consider {{fill ...}}
            content *= replace(inner,
                        Regex("({{\\s*fill\\s+$vname\\s*}})") => "$value")
        end
    else
        for value in locvar(iname)
            temp = inner
            for (vname, value) in zip(vnames, value)
                temp = replace(temp,
                        Regex("({{\\s*fill\\s+$vname\\s*}})") => "$value")
            end
            content *= temp
        end
    end
    @label final_step
    head = nextind(hs, to(β_close))
    return convert_html(content), head, i_close
end
