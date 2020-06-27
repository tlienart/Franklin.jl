"""
$(SIGNATURES)

Helper function to process an individual block when it's a `HFun` such as
`{{ fill author }}`. See also [`convert_html`](@ref).
"""
function convert_html_fblock(β::HFun)::String
    fun = Symbol("hfun_" * lowercase(β.fname))
    ex  = isempty(β.params) ? :($fun()) : :($fun($β.params))
    # see if a hfun was defined in utils
    if isdefined(Main, :Utils) && isdefined(Main.Utils, fun)
        res = Core.eval(Main.Utils, ex)
        return string(res)
    end
    # see if a hfun was defined internally
    isdefined(Franklin, fun) && return eval(ex)
    # if zero parameters, see if can fill (case: {{vname}})
    if isempty(β.params) &&
        (!isnothing(locvar(β.fname)) || β.fname in UTILS_NAMES)
        return hfun_fill([β.fname])
    end
    # if we get here, then the function name is unknown, warn and ignore
    @warn "I found a function block '{{$(β.fname) ...}}' but I don't " *
          "recognise the function name. Ignoring."
    # returning empty
    return ""
end


"""
$(SIGNATURES)

H-Function of the form `{{ fill vname }}` or `{{ fill vname rpath}}` to plug in
the content of a franklin-var `vname` (assuming it can be represented as a
string).
"""
function hfun_fill(params::Vector{String})::String
    # check params
    if length(params) > 2 || isempty(params)
        throw(HTMLFunctionError("{{fill ...}} should have one or two " *
                                "($(length(params)) given). Verify."))
    end
    # form the fill
    repl  = ""
    vname = params[1]
    if length(params) == 1
        if vname in UTILS_NAMES
            repl = string(getfield(Main.Utils, Symbol(vname)))
        else
            tmp_repl = locvar(vname)
            if isnothing(tmp_repl)
                @warn "I found a '{{fill $vname}}' but I do not know the " *
                      "variable '$vname'. Ignoring."
            else
                repl = string(tmp_repl)
            end
        end
    else # two parameters, look in a path
        rpath = params[2]
        tmp_repl = pagevar(rpath, vname)
        if isnothing(tmp_repl)
            @warn "I found a '{{fill $vname $rpath}}' but I do not know the " *
                  "variable '$vname' or the path '$rpath'. Ignoring."
        else
            repl = string(tmp_repl)
        end
    end
    return repl
end


"""
$(SIGNATURES)

H-Function of the form `{{ insert fpath }}` to plug in the content of a file at
`fpath`. Note that the base path is assumed to be `PATHS[:src_html]`
(`< v"0.2"`) and `PATHS[:layout]` otherwise and so paths have to be expressed
relative to that.
"""
function hfun_insert(params::Vector{String})::String
    # check params
    if length(params) != 1
        throw(HTMLFunctionError("I found a {{insert ...}} with more than one parameter. Verify."))
    end
    # apply
    repl   = ""
    layout = path(ifelse(FD_ENV[:STRUCTURE] < v"0.2", :src_html, :layout))
    fpath  = joinpath(layout, split(params[1], "/")...)
    if isfile(fpath)
        repl = convert_html(read(fpath, String))
    else
        @warn "I found an {{insert ...}} block and tried to insert '$fpath' but I couldn't find the file. Ignoring."
    end
    return repl
end


"""
$(SIGNATURES)

H-Function of the form `{{href ... }}`.
"""
function hfun_href(params::Vector{String})::String
    # check params
    if length(params) != 2
        throw(HTMLFunctionError("I found an {{href ...}} block and expected 2 parameters" *
                                "but got $(length(params)). Verify."))
    end
    # apply
    repl = "<b>??</b>"
    dname, hkey = params[1], params[2]
    if params[1] == "EQR"
        haskey(PAGE_EQREFS, hkey) || return repl
        repl = html_ahref_key(hkey, PAGE_EQREFS[hkey])
    elseif params[1] == "BIBR"
        haskey(PAGE_BIBREFS, hkey) || return repl
        repl = html_ahref_key(hkey, PAGE_BIBREFS[hkey])
    else
        @warn "Unknown dictionary name $dname in {{href ...}}. Ignoring"
    end
    return repl
end


"""
$(SIGNATURES)

H-Function of the form `{{toc min max}}` (table of contents). Where `min` and
`max` control the minimum level and maximum level of  the table of content.
The split is as follows:

* key is the refstring
* f[1] is the title (header text)
* f[2] is irrelevant (occurence, used for numbering)
* f[3] is the level
"""
function hfun_toc(params::Vector{String})::String
    if length(params) != 2
        throw(HTMLFunctionError("I found a {{toc ...}} block and expected 2 " *
                              "parameters but got $(length(params)). Verify."))
    end
    isempty(PAGE_HEADERS) && return ""

    # try to parse min-max level
    min = 0
    max = 100
    try
        min = parse(Int, params[1])
        max = parse(Int, params[2])
    catch
        throw(HTMLFunctionError("I found a {{toc min max}} but couldn't " *
                                "parse min/max. Verify."))
    end

    inner   = ""
    headers = filter(p -> min ≤ p.second[3] ≤ max, PAGE_HEADERS)
    baselvl = minimum(h[3] for h in values(headers)) - 1
    curlvl  = baselvl
    for (rs, h) ∈ headers
        lvl = h[3]
        if lvl ≤ curlvl
            # Close previous list item
            inner *= "</li>"
            # Close additional sublists for each level eliminated
            for i = curlvl-1:-1:lvl
                inner *= "</ol></li>"
            end
            # Reopen for this list item
            inner *= "<li>"
        elseif lvl > curlvl
            # Open additional sublists for each level added
            for i = curlvl+1:lvl
                inner *= "<ol><li>"
            end
        end
        inner *= html_ahref_key(rs, h[1])
        curlvl = lvl
        # At this point, number of sublists (<ol><li>) open equals curlvl
    end
    # Close remaining lists, as if going down to the base level
    for i = curlvl-1:-1:baselvl
        inner *= "</li></ol>"
    end
    toc = "<div class=\"franklin-toc\">" * inner * "</div>"
end


"""
$(SIGNATURES)

H-Function of the form `{{taglist}}`.
"""
function hfun_taglist()::String
    tag = locvar(:fd_tag)

    c = IOBuffer()
    write(c, "<ul>")

    rpaths = globvar("fd_tag_pages")[tag]
    sorter(p) = begin
        pvd = pagevar(p, "date")
        if isnothing(pvd)
            return Date(Dates.unix2datetime(stat(p * ".md").ctime))
        end
        return pvd
    end
    sort!(rpaths, by=sorter, rev=true)

    (:hfun_list, "tag: $tag, loop over $rpaths") |> logger

    for rpath in rpaths
        title = pagevar(rpath, "title")
        if isnothing(title)
            title = "/$rpath/"
        end
        url = get_url(rpath)
        write(c, "<li><a href=\"$url\">$title</a></li>")
    end
    write(c, "</ul>")
    return String(take!(c))
end
