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


"""
    isnothing(x)

Convenience function to check if a variable is `nothing`.
"""
isnothing(x) = (x == nothing)


"""
    fromto(s, β)

Convenience function to chop a string around a `β.from`, `β.to`.
"""
fromto(s, β) = subs(s, β.from, β.to)
