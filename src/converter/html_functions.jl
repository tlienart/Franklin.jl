"""
$(SIGNATURES)

Helper function to process an individual block when it's a `HFun` such as `{{ fill author }}`.
Dev Note: `fpath` is (currently) unused but is passed to all `convert_html_block` functions.
See [`convert_html`](@ref).
"""
function convert_html_block(β::HFun, allvars::PageVars, ::AS="")::String
    # normalise function name and apply the function
    fn = lowercase(β.fname)
    haskey(HTML_FUNCTIONS, fn) && return HTML_FUNCTIONS[fn](β.params, allvars)
    # if we get here, then the function name is unknown, warn and ignore
    @warn "I found a function block '{{$fn ...}}' but don't recognise the function name. Ignoring."
    return ""
end


"""
$(SIGNATURES)

H-Function of the form `{{ fill vname }}` to plug in the content of a jd-var `vname` (assuming it
can be represented as a string).
"""
function hfun_fill(params::Vector{String}, allvars::PageVars)::String
    # check params
    if length(params) != 1
        throw(HTMLFunctionError("I found a {{fill ...}} with more than one parameter. Verify."))
    end
    # form the fill
    replacement = ""
    vname = params[1]
    if haskey(allvars, vname)
        # retrieve the value stored
        tmp_repl = allvars[vname].first
        isnothing(tmp_repl) || (replacement = string(tmp_repl))
    else
        @warn "I found a '{{fill $vname}}' but I do not know the variable '$vname'. Ignoring."
    end
    return replacement
end


"""
$(SIGNATURES)

H-Function of the form `{{ insert fpath }}` to plug in the content of a file at `fpath`. Note that
the base path is assumed to be `PATHS[:src_html]` so paths have to be expressed relative to that.
"""
function hfun_insert(params::Vector{String})::String
    # check params
    if length(params) != 1
        throw(HTMLFunctionError("I found a {{insert ...}} with more than one parameter. Verify."))
    end
    # apply
    replacement = ""
    fpath = joinpath(PATHS[:src_html], split(params[1], "/")...)
    if isfile(fpath)
        replacement = convert_html(read(fpath, String), merge(GLOBAL_PAGE_VARS, LOCAL_PAGE_VARS))
    else
        @warn "I found an {{insert ...}} block and tried to insert '$fpath' but I couldn't find the file. Ignoring."
    end
    return replacement
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
    replacement = "<b>??</b>"
    dname, hkey = params[1], params[2]
    if params[1] == "EQR"
        haskey(PAGE_EQREFS, hkey) || return replacement
        replacement = html_ahref_key(hkey, PAGE_EQREFS[hkey])
    elseif params[1] == "BIBR"
        haskey(PAGE_BIBREFS, hkey) || return replacement
        replacement = html_ahref_key(hkey, PAGE_BIBREFS[hkey])
    else
        @warn "Unknown dictionary name $dname in {{href ...}}. Ignoring"
    end
    return replacement
end


"""
$(SIGNATURES)

H-Function of the form `{{toc}}` (table of contents).
The split is as follows:

* h[1] is the header text
* h[2] is the key to the header
* h[3] indicates how many time title occurs (usually once but if more then helps avoid clashes)
* h[4] indicates the level of the title
"""
function hfun_toc()::String
    inner   = ""
    baselvl = minimum(h[4] for h in values(PAGE_HEADERS)) - 1
    curlvl  = baselvl
    for i ∈ 1:length(PAGE_HEADERS)
        h = PAGE_HEADERS[i]
        lvl = h[4]
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
        inner *= html_ahref_key(h[2], h[1])
        curlvl = lvl
        # At this point, number of sublists (<ol><li>) open equals curlvl
    end
    # Close remaining lists, as if going down to the base level
    for i = curlvl-1:-1:baselvl
        inner *= "</li></ol>"
    end
    toc = "<div class=\"jd-toc\">" * inner * "</div>"
end


"""
HTML_FUNCTIONS

Dictionary for special html functions. They can take two variables, the first one `π` refers to the
arguments passed to the function, the second one `ν` refers to the page variables (i.e. the
context) available to the function.
"""
const HTML_FUNCTIONS = Dict{String, Function}(
    "fill"   => ((π, ν) -> hfun_fill(π, ν)),
    "insert" => ((π, _) -> hfun_insert(π)),
    "href"   => ((π, _) -> hfun_href(π)),
    "toc"    => ((_, _) -> hfun_toc()),
    )
