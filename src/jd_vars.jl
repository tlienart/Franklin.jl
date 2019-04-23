"""
    JD_GLOB_VARS

Dictionary of variables assumed to be set for the entire website. Entries have the format
KEY => PAIR where KEY is a string (e.g.: "author") and PAIR is a pair where the first element is
the default value for the variable and the second is a tuple of accepted possible (super)types
for that value. (e.g.: "THE AUTHOR" => (String, Nothing))

DEVNOTE: marked as constant for perf reasons but can be modified since Dict.
"""
const JD_GLOB_VARS = JD_VAR_TYPE()


"""
$(SIGNATURES)

Convenience function to allocate default values of the global site variables. This is called once,
when JuDoc is started.
"""
@inline function def_GLOB_VARS!()::Nothing
    empty!(JD_GLOB_VARS)
    JD_GLOB_VARS["author"]      = Pair("THE AUTHOR",   (String, Nothing))
    JD_GLOB_VARS["date_format"] = Pair("U dd, yyyy",   (String,))
    JD_GLOB_VARS["baseurl"]     = Pair(nothing,        (String, Nothing))
    JD_GLOB_VARS["codetheme"]   = Pair(Themes.DefaultTheme, (Highlights.AbstractTheme, Nothing))
    return nothing
end


"""
    JD_LOC_VARS

Dictionary of variables copied and then set for each page (through definitions). Entries have the
same format as for `JD_GLOB_VARS`.

DEVNOTE: marked as constant for perf reasons but can be modified since Dict.
"""
const JD_LOC_VARS = JD_VAR_TYPE()


"""
$(SIGNATURES)

Convenience function to allocate default values of page variables. This is called every time a page
is processed.
"""
@inline function def_LOC_VARS!()::Nothing
    empty!(JD_LOC_VARS)
    JD_LOC_VARS["title"]    = Pair(nothing, (String, Nothing))
    JD_LOC_VARS["hasmath"]  = Pair(true,    (Bool,))
    JD_LOC_VARS["hascode"]  = Pair(false,   (Bool,))
    JD_LOC_VARS["date"]     = Pair(Date(1), (String, Date, Nothing))
    JD_LOC_VARS["jd_ctime"] = Pair(Date(1), (Date,))
    JD_LOC_VARS["jd_mtime"] = Pair(Date(1), (Date,))
    return nothing
end


"""
    JD_GLOB_LXDEFS

List of latex definitions accessible to all pages. This is filled when the config file is read
(via manager/file_utils/process_config).
"""
const JD_GLOB_LXDEFS = Dict{String, LxDef}()


"""
    def_GLOB_LXDEFS!

Convenience function to allocate default values of global latex commands accessible throughout
the site. See [`resolve_lxcom`](@ref).
"""
@inline function def_GLOB_LXDEFS!()::Nothing
    empty!(JD_GLOB_LXDEFS)
    # hyperreferences
    JD_GLOB_LXDEFS["\\eqref"]    = LxDef("\\eqref",    1, SubString(""))
    JD_GLOB_LXDEFS["\\cite"]     = LxDef("\\cite",     1, SubString(""))
    JD_GLOB_LXDEFS["\\citet"]    = LxDef("\\citet",    1, SubString(""))
    JD_GLOB_LXDEFS["\\citep"]    = LxDef("\\citep",    1, SubString(""))
    JD_GLOB_LXDEFS["\\biblabel"] = LxDef("\\biblabel", 2, SubString(""))
    # inclusion
    JD_GLOB_LXDEFS["\\input"]    = LxDef("\\input",    2, SubString(""))
    return nothing
end


#= ==========================================
Convenience functions related to the jd_vars
============================================= =#

"""
$(SIGNATURES)

Convenience function taking a `DateTime` object and returning the corresponding formatted string
with the format contained in `JD_GLOB_VARS["date_format"]`.
"""
jd_date(d::DateTime)::AbstractString = Dates.format(d, JD_GLOB_VARS["date_format"].first)


"""
$(SIGNATURES)

Checks if a data type `t` is a subtype of a tuple of accepted types `tt`.
"""
is_ok_type(t::DataType, tt::NTuple{N,DataType} where N)::Bool = any(<:(t, tᵢ) for tᵢ ∈ tt)


"""
$(SIGNATURES)

Take a var dictionary `dict` and update the corresponding pair. This should only be used internally
as it does not check the validity of `val`. See [`write_page`](@ref) where it is used to store a
file's creation and last modification time.
"""
set_var!(d::JD_VAR_TYPE, k::K, v) where K = (d[k] = Pair(v, d[k].second); nothing)


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
function set_vars!(jd_vars::JD_VAR_TYPE, assignments::Vector{Pair{String,String}})::JD_VAR_TYPE
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
            if is_ok_type(type_tmp, acc_types)
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
