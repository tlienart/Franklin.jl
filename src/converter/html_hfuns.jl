"""
JD_HTML_FUNS

Dictionary for special html functions. They can take two variables, the first one `π` refers to the
arguments passed to the function, the second one `ν` refers to the page variables (i.e. the
context) available to the function.
"""
const JD_HTML_FUNS = Dict{String, Function}(
    "fill"   => ((π, ν) -> hfun_fill(π, ν)),
    "insert" => ((π, _) -> hfun_insert(π)),
    "href"   => ((π, _) -> hfun_href(π)),
    )


"""
$(SIGNATURES)

Helper function to process an individual block when it's a `HFun` such as `{{ fill author }}`.
Dev Note: `fpath` is (currently) unused but is passed to all `convert_hblock` functions.
See [`convert_html`](@ref).
"""
function convert_hblock(β::HFun, allvars::JD_VAR_TYPE, ::AbstractString="")::String
    # normalise function name and apply the function
    fn = lowercase(β.fname)
    haskey(JD_HTML_FUNS, fn) && return JD_HTML_FUNS[fn](β.params, allvars)

    # if here, then the function name is unknown, warn and ignore
    @warn "I found a function block '{{$fn ...}}' but I don't recognise this function name. Ignoring."
    return ""
end


"""
$(SIGNATURES)

H-Function of the form `{{ fill vname }}` to plug in the content of a jd-var `vname` (assuming it
can be represented as a string).
"""
function hfun_fill(params::Vector{String}, allvars::JD_VAR_TYPE)::String
    # check params
    length(params) == 1 || error("I found a {{fill ...}} with more than one parameter. Verify.")
    # fill
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
the base path is assumed to be `JD_PATHS[:in_html]` so paths have to be expressed relative to that.
Note that (at the moment) the content is inserted "as is" without further processing which means
that any `{{...}}` block in the inserted content will be displayed "as is".
"""
function hfun_insert(params::Vector{String})::String
    # check params
    length(params) == 1 || error("I found an {{insert ...}} block with more than one parameter. Verify.")
    # apply
    replacement = ""
    fpath = joinpath(JD_PATHS[:in_html], params[1])
    if isfile(fpath)
        replacement = read(fpath, String)
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
    length(params) == 2 || error("I found an {{href ...}} block and expected 2 parameters but got $(length(params)). Verify.")
    # apply
    replacement = "<b>??</b>"
    dname, hkey = params[1], params[2]
    if params[1] == "EQR"
        haskey(JD_LOC_EQDICT, hkey) || return replacement
        replacement = html_ahref(hkey, JD_LOC_EQDICT[hkey])
    elseif params[1] == "BIBR"
        haskey(JD_LOC_BIBREFDICT, hkey) || return replacement
        replacement = html_ahref(hkey, JD_LOC_BIBREFDICT[hkey])
    else
        @warn "Unknown dictionary name $dname in {{href ...}}. Ignoring"
    end
    return replacement
end


"""
$(SIGNATURES)

Convenience function to introduce a hyper reference.
"""
html_ahref(key::AbstractString, name::Union{Int,String})::String = "<a href=\"#$key\">$name</a>"


"""
$(SIGNATURES)

Convenience function to introduce a div block.
"""
html_div(name::AbstractString, in::AbstractString)::String = "<div class=\"$name\">$in</div>\n"
