"""
	JD_GLOB_VARS

Dictionary of variables assumed to be set for the entire website. Entries have
the format KEY => PAIR where
* KEY is a string (e.g.: "author")
* PAIR is an pair where the first element is the default value for the variable
and the second is a tuple of accepted possible (super)types for that value. (e.g.: "THE AUTHOR" => (String, Void))
It is a global that gets modified having an impact on all pages.
"""
global JD_GLOB_VARS = Dict{String, Pair{Any, Tuple}}(
	"author" => Pair("THE AUTHOR", (String, Void)),
    "date_format" => Pair("U dd, yyyy", (String,))
    )


"""
    JD_LOC_VARS

Dictionary of variables copied and then set for each page (through definitions).
Entries have the same format as for `JD_GLOB_VARS`.
It is a constant that gets copied for every page that is being looked at.
"""
const JD_LOC_VARS = Dict{String, Pair{Any, Tuple}}(
    "hasmath"  => Pair(true, (Bool,)),
    "hascode"  => Pair(false, (Bool,)),
    "isnotes"  => Pair(true, (Bool,)),
    "title"    => Pair("THE TITLE", (String,)),
    "date"     => Pair(Date(), (String, Date, Void)),
    "jd_ctime" => Pair(Date(), (Date,)),
    "jd_mtime" => Pair(Date(), (Date,)),
    )


"""
    JD_GLOB_LXDEFS

List of latex definitions accessible to all pages.
"""
global JD_GLOB_LXDEFS = Vector{LxDef}()


"""
    jd_date(d)

Convenience function taking a `DateTime` object and returning the corresponding
formatted string with the format contained in `JD_GLOB_VARS["date_format"]`.
"""
jd_date(d::DateTime) = Dates.format(d, JD_GLOB_VARS["date_format"].first)


"""
    is_ok_type(t, tt)

Checks if a data type `t` is a subtype of a tuple of accepted types `tt`.
"""
is_ok_type(t, tt) = any(issubtype(t, tᵢ) for tᵢ ∈ tt)


"""
    set_var(dict, key, val)

Take a var dictionary `dict` and update the corresponding pair. This should
only be used internally as it does not check the validity of `val`.
See `write_page` where it is used to store a file's creation and last
modification time.
"""
set_var!(dict, key, val) = (dict[key] = Pair(val, dict[key].second))



"""
    set_vars!(jd_vars, assignments)

Given a set of definitions `assignments`, update the variables dictionary
`jd_vars`. Keys in `assignments` that do not match keys in `jd_vars` are
ignored (a warning message is displayed).
The entries in `assignments` are of the form `KEY=>STR` where `KEY` is a
string key (e.g.: "hasmath") and `STR` is an assignment to evaluate (e.g.:
"=false").

Example:

    ```
    d = Dict("a"=>(0.5=>(Real,)), "b"=>("hello"=>(String,)))
    set_vars!(d, ["a"=>"=5.0", "b"=>"= \"goodbye\""])
    ```

Will return

    ```
    Dict{String,Any} with 2 entries:
      "b" => "goodbye"
      "a" => 5.0
    ```
"""
function set_vars!(
    jd_vars::Dict{String, Pair{Any, Tuple}},
    assignments::Vector{Pair{String, String}})

    if !isempty(assignments)
        for (key, assign) ∈ assignments
            if haskey(jd_vars, key)
                tmp = parse("__tmp__ = " * assign)
                # try to evaluate the parsed assignment
                try
                    tmp = eval(tmp)
                catch err
                    warn("I got an error trying to evaluate '$tmp', fix the assignment.")
                    throw(err)
                end
                # if the retrieved value has the right type, assign it to
                # the corresponding key
                type_tmp = typeof(tmp)
                acc_types = jd_vars[key].second
                if is_ok_type(type_tmp, acc_types)
                    jd_vars[key] = Pair(tmp, acc_types)
                else
                    warn("Doc var '$key' (type(s): $acc_types) can't be set to value '$tmp' (type: $type_tmp). Assignment ignored.")
                end
            else
                warn("Doc var name '$key' is unknown. Assignment ignored.")
            end
        end
    end
end
