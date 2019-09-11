"""
GLOBAL_PAGE_VARS

Dictionary of variables assumed to be set for the entire website. Entries have the format
KEY => PAIR where KEY is a string (e.g.: "author") and PAIR is a pair where the first element is
the default value for the variable and the second is a tuple of accepted possible (super)types
for that value. (e.g.: "THE AUTHOR" => (String, Nothing))

DEVNOTE: marked as constant for perf reasons but can be modified since Dict.
"""
const GLOBAL_PAGE_VARS = PageVars()


"""
$(SIGNATURES)

Convenience function to allocate default values of the global site variables. This is called once,
when JuDoc is started.
"""
@inline function def_GLOBAL_PAGE_VARS!()::Nothing
    empty!(GLOBAL_PAGE_VARS)
    GLOBAL_PAGE_VARS["author"]      = Pair("THE AUTHOR",   (String, Nothing))
    GLOBAL_PAGE_VARS["date_format"] = Pair("U dd, yyyy",   (String,))
    GLOBAL_PAGE_VARS["prepath"]     = Pair("",             (String,))
    return nothing
end


"""
LOCAL_PAGE_VARS

Dictionary of variables copied and then set for each page (through definitions). Entries have the
same format as for `GLOBAL_PAGE_VARS`.

DEVNOTE: marked as constant for perf reasons but can be modified since Dict.
"""
const LOCAL_PAGE_VARS = PageVars()


"""
$(SIGNATURES)

Convenience function to allocate default values of page variables. This is called every time a page
is processed.
"""
@inline function def_LOCAL_PAGE_VARS!()::Nothing
    empty!(LOCAL_PAGE_VARS)
    LOCAL_PAGE_VARS["title"]    = Pair(nothing, (String, Nothing))
    LOCAL_PAGE_VARS["hasmath"]  = Pair(true,    (Bool,))
    LOCAL_PAGE_VARS["hascode"]  = Pair(false,   (Bool,))
    LOCAL_PAGE_VARS["date"]     = Pair(Date(1), (String, Date, Nothing))
    LOCAL_PAGE_VARS["jd_ctime"] = Pair(Date(1), (Date,))   # time of creation
    LOCAL_PAGE_VARS["jd_mtime"] = Pair(Date(1), (Date,))   # time of last modification
    LOCAL_PAGE_VARS["jd_rpath"] = Pair("",      (String,)) # local path to file src/[...]/blah.md
    LOCAL_PAGE_VARS["lang"]     = Pair("julia", (String,)) # default lang for indented code
    LOCAL_PAGE_VARS["reflinks"] = Pair(true,    (Bool,))   # whether there are reflinks or not
    return nothing
end


"""
PAGE_HEADERS

Keep track of seen headers. The key amounts to the ordering (~ordered dict), the value contains
the title, the refstring version of the title, the occurence number and the level (1, ..., 6).
"""
const PAGE_HEADERS = Dict{Int,Tuple{AbstractString,AbstractString,Int,Int}}()


"""
$(SIGNATURES)
"""
@inline function def_PAGE_HEADERS!()::Nothing
    empty!(PAGE_HEADERS)
    return nothing
end


"""
GLOBAL_LXDEFS

List of latex definitions accessible to all pages. This is filled when the config file is read
(via manager/file_utils/process_config).
"""
const GLOBAL_LXDEFS = Dict{String, LxDef}()


"""
EMPTY_SS

Convenience constant for an empty substring, used in LXDEFS.
"""
const EMPTY_SS = SubString("")


"""
$(SIGNATURES)

Convenience function to allocate default values of global latex commands accessible throughout
the site. See [`resolve_lxcom`](@ref).
"""
@inline function def_GLOBAL_LXDEFS!()::Nothing
    empty!(GLOBAL_LXDEFS)
    # hyperreferences
    GLOBAL_LXDEFS["\\eqref"]    = LxDef("\\eqref",    1, EMPTY_SS)
    GLOBAL_LXDEFS["\\cite"]     = LxDef("\\cite",     1, EMPTY_SS)
    GLOBAL_LXDEFS["\\citet"]    = LxDef("\\citet",    1, EMPTY_SS)
    GLOBAL_LXDEFS["\\citep"]    = LxDef("\\citep",    1, EMPTY_SS)
    GLOBAL_LXDEFS["\\label"]    = LxDef("\\label",    1, EMPTY_SS)
    GLOBAL_LXDEFS["\\biblabel"] = LxDef("\\biblabel", 2, EMPTY_SS)
    GLOBAL_LXDEFS["\\toc"]      = LxDef("\\toc",      0, subs("~~~{{toc}}~~~"))
    GLOBAL_LXDEFS["\\tableofcontents"] = LxDef("\\tableofcontents", 0, subs("~~~{{toc}}~~~"))
    # inclusion
    GLOBAL_LXDEFS["\\input"]      = LxDef("\\input",      2, EMPTY_SS)
    GLOBAL_LXDEFS["\\output"]     = LxDef("\\output",     1, EMPTY_SS)
    GLOBAL_LXDEFS["\\textoutput"] = LxDef("\\textoutput", 1, EMPTY_SS)
    GLOBAL_LXDEFS["\\textinput"]  = LxDef("\\textinput", 1, EMPTY_SS)
    GLOBAL_LXDEFS["\\figalt"]     = LxDef("\\figalt",     2, EMPTY_SS)
    GLOBAL_LXDEFS["\\fig"]        = LxDef("\\fig",        1, subs("\\figalt{}{#1}"))
    GLOBAL_LXDEFS["\\file"]       = LxDef("\\file",       2, subs("[#1]()"))
    GLOBAL_LXDEFS["\\tableinput"] = LxDef("\\tableinput", 2, EMPTY_SS)
    # text formatting
    GLOBAL_LXDEFS["\\underline"] = LxDef("\\underline", 1,
                            subs("~~~<span style=\"text-decoration:underline;\">!#1</span>~~~"))
    GLOBAL_LXDEFS["\\textcss"]   = LxDef("\\underline", 2,
                            subs("~~~<span style=\"!#1\">!#2</span>~~~"))
    return nothing
end


#= ==========================================
Convenience functions related to the jd_vars
============================================= =#

"""
$(SIGNATURES)

Convenience function taking a `DateTime` object and returning the corresponding formatted string
with the format contained in `GLOBAL_PAGE_VARS["date_format"]`.
"""
jd_date(d::DateTime)::AbstractString = Dates.format(d, GLOBAL_PAGE_VARS["date_format"].first)


"""
$(SIGNATURES)

Checks if a data type `t` is a subtype of a tuple of accepted types `tt`.
"""
check_type(t::DataType, tt::NTuple{N,DataType} where N)::Bool = any(<:(t, tᵢ) for tᵢ ∈ tt)


"""
$(SIGNATURES)

Take a var dictionary `dict` and update the corresponding pair. This should only be used internally
as it does not check the validity of `val`. See [`write_page`](@ref) where it is used to store a
file's creation and last modification time.
"""
set_var!(d::PageVars, k::K, v) where K = (d[k] = Pair(v, d[k].second); nothing)


#= =================================================
set_vars, the key function to assign site variables
==================================================== =#

"""
$(SIGNATURES)

Given a set of definitions `assignments`, update the variables dictionary `jd_vars`. Keys in
`assignments` that do not match keys in `jd_vars` are ignored (a warning message is displayed).
The entries in `assignments` are of the form `KEY => STR` where `KEY` is a string key (e.g.:
"hasmath") and `STR` is an assignment to evaluate (e.g.: "=false").

# Example:

```julia-repl
julia> d = Dict("a"=>(0.5=>(Real,)), "b"=>("hello"=>(String,)));
julia> JuDoc.set_vars!(d, ["a"=>"5.0", "b"=>"\"goodbye\""])
Dict{String,Pair{K,Tuple{DataType}} where K} with 2 entries:
  "b" => "goodbye"=>(String,)
  "a" => 5.0=>(Real,)
```
"""
function set_vars!(jd_vars::PageVars, assignments::Vector{Pair{String,String}})::PageVars
    # if there's no assignment, cut it short
    isempty(assignments) && return jd_vars
    # process each assignment in turn
    for (key, assign) ∈ assignments
        # at this point there may still be a comment in the assignment
        # string e.g. if it came from @def title = "blah" <!-- ... -->
        # so let's strip <!-- and everything after.
        # NOTE This is agressive so if it happened that the user wanted # this in a string it would fail (but come on...)
        idx = findfirst("<!--", assign)
        !isnothing(idx) && (assign = assign[1:prevind(assign, idx[1])])
        tmp = Meta.parse("__tmp__ = " * assign)
        # try to evaluate the parsed assignment
        try
            tmp = eval(tmp)
        catch err
            @error "I got an error (of type '$(typeof(err))') trying to evaluate '$tmp', fix the assignment."
            break
        end

        if haskey(jd_vars, key)
            # if the retrieved value has the right type, assign it to the corresponding key
            type_tmp  = typeof(tmp)
            acc_types = jd_vars[key].second
            if check_type(type_tmp, acc_types)
                jd_vars[key] = Pair(tmp, acc_types)
            else
                @warn "Doc var '$key' (type(s): $acc_types) can't be set to value '$tmp' (type: $type_tmp). Assignment ignored."
            end
        else
            # there is no key, so directly assign, the type is not checked
            jd_vars[key] = Pair(tmp, (typeof(tmp), ))
        end
    end
    return jd_vars
end
