
# Convenience functions to work with strings and substrings

"""
    str(s)

Returns the string corresponding to `s`, `s` itself if it is a string, or the
parent string if `s` is a substring. This does not allocate.
"""
str(s::String) = s
str(s::SubString) = s.string


"""
    subs(s, from, to)
    subs(s, from)
    subs(s, range)

Convenience functions to take a substring of a string. This only allocates for
the creation of a substring object (i.e. extremely little).
"""
subs(s::AbstractString, from::Int, to::Int) = SubString(s, from, to)
subs(s::AbstractString, from::Int) = subs(s, from, from)
subs(s::AbstractString, range::UnitRange{Int}) = SubString(s, range)


"""
    from(ss)

Given a substring `ss`, returns the position in the parent string where the
substring starts.
"""
from(ss::SubString) = nextind(str(ss), ss.offset)


"""
    to(ss)

Given a substring `ss`, returns the position in the parent string where the
substring ends.
"""
to(ss::SubString) = ss.offset + ss.ncodeunits

# Other convenience functions

"""
    time_it_took(start)

Convenience function to display a time since `start`.
"""
function time_it_took(start)
    comp_time = time() - start
    mess = comp_time > 60 ? "$(round(comp_time/60;   digits=1))m" :
           comp_time > 1 ?  "$(round(comp_time;      digits=1))s" :
                            "$(round(comp_time*1000; digits=1))ms"
    mess = "✅ [done $mess]"
    println(mess)
end


"""
    isnothing(x)

Convenience function to check if a variable is `nothing`.
"""
isnothing(x) = (x == nothing)
