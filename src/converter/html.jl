"""
$(SIGNATURES)

Convert a judoc html string into a html string (i.e. replace `{{ ... }}` blocks).
"""
function convert_html(hs::AS, allvars::PageVars; isoptim::Bool=false)::String
    # Tokenize
    tokens = find_tokens(hs, HTML_TOKENS, HTML_1C_TOKENS)

    # Find hblocks ({{ ... }})
    hblocks, tokens = find_all_ocblocks(tokens, HTML_OCB)
    filter!(hb -> hb.name != :COMMENT, hblocks)

    # Find qblocks (qualify the hblocks)
    qblocks = qualify_html_hblocks(hblocks)

    fhs = process_html_qblocks(hs, allvars, qblocks)

    # See issue #204, basically not all markdown links are processed  as
    # per common mark with the JuliaMarkdown, so this is a patch that kind
    # of does
    if haskey(allvars, "reflinks") && allvars["reflinks"].first
        fhs = find_and_fix_md_links(fhs)
    end
    # if it ends with </p>\n but doesn't start with <p>, chop it off
    # this may happen if the first element parsed is an ocblock (not text)
    δ = ifelse(endswith(fhs, "</p>\n") && !startswith(fhs, "<p>"), 5, 0)

    isempty(fhs) && return ""

    if !isempty(GLOBAL_PAGE_VARS["prepath"].first) && isoptim
        fhs = fix_links(fhs)
    end

    return String(chop(fhs, tail=δ))
end


"""
$SIGNATURES

Return the HTML corresponding to a JuDoc-Markdown string.
"""
function jd2html(st::AbstractString; internal::Bool=false, dir::String="")::String
    if !internal
        FOLDER_PATH[] = isempty(dir) ? mktempdir() : dir
        set_paths!()
        CUR_PATH[] = "index.md"
        def_GLOBAL_LXDEFS!()
        def_GLOBAL_PAGE_VARS!()
    end
    m, v = convert_md(st * EOS, collect(values(GLOBAL_LXDEFS)); isinternal=internal)
    h = convert_html(m, v)
    return h
end

"""
$SIGNATURES

Take a qualified html block stack and go through it, with recursive calling.
"""
function process_html_qblocks(hs::AS, allvars::PageVars, qblocks::Vector{AbstractBlock},
                              head::Int=1, tail::Int=lastindex(hs))::String
    htmls = IOBuffer()
    head  = head # (sub)string index
    i     = 1    # qualified block index
    while i ≤ length(qblocks)
        β = qblocks[i]
        # write what's before the block
        fromβ = from(β)
        (head < fromβ) && write(htmls, subs(hs, head, prevind(hs, fromβ)))

        if β isa HTML_OPEN_COND
            content, head, i = process_html_cond(hs, allvars, qblocks, i)
            write(htmls, content)
        # should not see an HEnd by itself --> error
        elseif β isa HEnd
            throw(HTMLBlockError("I found a lonely {{end}}."))
        # it's a function block, process it
        else
            write(htmls, convert_html_fblock(β, allvars))
            head = nextind(hs, to(β))
        end
        i += 1
    end
    # write whatever is left after the last block
    head ≤ tail && write(htmls, subs(hs, head, tail))
    return String(take!(htmls))
end


"""
$SIGNATURES

Recursively process a conditional block from an opening HTML_COND_OPEN to a {{end}}.
"""
function process_html_cond(hs::AS, allvars::PageVars, qblocks::Vector{AbstractBlock},
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
                accept_elseif || throw(HTMLBlockError("Saw a {{elseif ...}} after a "*
                                                      "{{else}} block."))
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
            k = Int(haskey(allvars, βi.vname))
        elseif βi isa HIsNotDef
            k = Int(!haskey(allvars, βi.vname))
        else
            # current path is relative to /src/ for instance
            # /src/pages/blah.md -> pages/blah
            # if starts with `pages/`, replaces by `pub/`: pages/blah => pub/blah
            rpath = splitext(unixify(CUR_PATH[]))[1]
            rpath = replace(rpath, Regex("^pages") => "pub")
            # compare with β.pages
            inpage = any(p -> splitext(p)[1] == rpath, βi.pages)

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
        known = [haskey(allvars, c) for c in conds]

        if !all(known)
            idx = findfirst(.!known)
            throw(HTMLBlockError("At least one of the condition variable could not be found: " *
                                 "couldn't find '$(conds[idx])'."))
        end
        # check that all these variables are bool
        bools = [isa(allvars[c].first, Bool) for c  in conds]
        if !all(bools)
            idx = findfirst(.!bools)
            throw(HTMLBlockError("At least one of the condition variable is not a Bool: " *
                                 "'$(conds[idx])' is not a bool."))
        end
        # which one is verified?
        u = findfirst(c -> allvars[c].first, conds)
        k = isnothing(u) ? 0 : u + lag
    end

    if iszero(k)
        # if we still haven't found a verified condition, use the else if there is one
        if !iszero(else_idx)
            # use elseblock, the content is from it to the β_close
            head = nextind(hs, to(qblocks[else_idx]))
            tail = prevind(hs, from(β_close))
            # get the stack of blocks in there
            action_qblocks = qblocks[else_idx+1:i_close-1]
            # process
            content = process_html_qblocks(hs, allvars, action_qblocks, head, tail)
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
        content = process_html_qblocks(hs, allvars, action_qblocks, head, tail)
    end
    # move the head after the final {{end}}
    head = nextind(hs, to(β_close))

    return content, head, i_close
end
