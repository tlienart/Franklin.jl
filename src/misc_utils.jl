
# Convenience functions to work with strings and substrings

"""
    str(s)

Returns the string corresponding to `s`, `s` itself if it is a string, or the parent string if `s`
is a substring.

DEVNOTE: this does not allocate.
"""
str(s::String)    = s
str(s::SubString) = s.string


"""
    subs(s, from, to)
    subs(s, from)
    subs(s, range)

Convenience functions to take a substring of a string.

DEVNOTE: this only allocates for the creation of a substring object (i.e. extremely little).
"""
subs(s::AbstractString, from::Int, to::Int)    = SubString(s, from, to)
subs(s::AbstractString, from::Int)             = subs(s, from, from)
subs(s::AbstractString, range::UnitRange{Int}) = SubString(s, range)


"""
    from(ss)

Given a substring `ss`, returns the position in the parent string where the substring starts.
"""
from(ss::SubString) = nextind(str(ss), ss.offset)


"""
    to(ss)

Given a substring `ss`, returns the position in the parent string where the substring ends.
"""
to(ss::SubString) = ss.offset + ss.ncodeunits


"""
    matchrange(m::RegexMatch)

Returns the string span of a regex match. Assumes there's no unicode in the match.
"""
matchrange(m::RegexMatch) = m.offset .+ (0:(length(m.match)-1))

# Other convenience functions

"""
    time_it_took(start)

Convenience function to display a time since `start`.
"""
function time_it_took(start)
    comp_time = time() - start
    mess = comp_time > 60 ? "$(round(comp_time/60;   digits=1))m" :
           comp_time >  1 ? "$(round(comp_time;      digits=1))s" :
                            "$(round(comp_time*1000; digits=1))ms"
    mess = "[done $(lpad(mess, 6))]"
    println(mess)
    return nothing
end


"""
    isnothing(x)

Convenience function to check if a variable is `nothing`.
"""
isnothing(x) = (x === nothing)


"""
    mathenv(s)

Convenience function to denote a string as being in a math context in a recursive parsing
situation. These blocks will be processed as math blocks but without adding KaTeX elements to it
given that they are part of a larger context that already has KaTeX elements.
NOTE: this happens when resolving latex commands in a math environment. So for instance if you have
`\$\$ x \\in \\R \$\$` and `\\R` is defined as a command that does `\\mathbb{R}` well that would be
an embedded math environment. These environments are marked as such so that we don't add additional
KaTeX markers around them.
"""
mathenv(s) = "_\$>_" * s * "_\$<_"


"""
    refstring(s)

Creates a random string pegged to `s` that we can use to make references. We could just use the
hash but it's quite long, here the length of the output is controlled  by `JD_LEN_RANDSTRING` which
is usually set to 4.
"""
refstring(s) = randstring(MersenneTwister(hash(s)), JD_LEN_RANDSTRING)
