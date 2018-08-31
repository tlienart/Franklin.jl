"""
    time_it_took(start)

Convenience function to display a time since `start`.
"""
function time_it_took(start)
    comp_time = time() - start
    mess = comp_time > 60 ? "$(round(comp_time/60; digits=1))m" :
           comp_time > 1 ? "$(round(comp_time; digits=1))s" :
           "$(round(comp_time*1000; digits=1))ms"
    mess = "[done $mess]"
    println(mess)
end


"""
    subs(s, from, to)

Convenience function to form a `SubString`.
"""
subs(s::AbstractString, from::Int, to::Int) = SubString(s, from, to)
subs(s::AbstractString, from::Int) = subs(s, from, from)


from(s::SubString) = s.offset+1
from(τ::Token) = from(τ.ss)
to(s::SubString) = s.offset+s.ncodeunits
to(τ::Token) = to(τ.ss)
str(τ::Token) = τ.ss.string

"""
    isnothing(x)

Convenience function to check if a variable is `nothing`.
"""
isnothing(x) = (x == nothing)
