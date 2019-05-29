
# Convenience functions to work with strings and substrings

"""
$(SIGNATURES)

Returns the string corresponding to `s`: `s` itself if it is a string, or the parent string if `s`
is a substring. Do not confuse with `String(s::SubString)` which casts `s` into its own object.

# Example

```julia-repl
julia> a = SubString("hello JuDoc", 3:8);
julia> JuDoc.str(a)
"hello JuDoc"
julia> String(a)
"llo Ju"
```
"""
str(s::String)::String    = s
str(s::SubString)::String = s.string


"""
    subs(s, from, to)
    subs(s, from)
    subs(s, range)

Convenience functions to take a substring of a string.

# Example
```julia-repl
julia> JuDoc.subs("hello", 2:4)
"ell"
```
"""
subs(s::AbstractString, from::Int, to::Int)::SubString    = SubString(s, from, to)
subs(s::AbstractString, from::Int)::SubString             = subs(s, from, from)
subs(s::AbstractString, range::UnitRange{Int})::SubString = SubString(s, range)


"""
$(SIGNATURES)

Given a substring `ss`, returns the position in the parent string where the substring starts.

# Example
```julia-repl
julia> ss = SubString("hello", 2:4); JuDoc.from(ss)
2
```
"""
from(ss::SubString)::Int = nextind(str(ss), ss.offset)


"""
$(SIGNATURES)

Given a substring `ss`, returns the position in the parent string where the substring ends.

# Example
```julia-repl
julia> ss = SubString("hello", 2:4); JuDoc.to(ss)
4
```
"""
to(ss::SubString)::Int = ss.offset + ss.ncodeunits


"""
$(SIGNATURES)

Returns the string span of a regex match. Assumes there is no unicode in the match.

# Example
```julia-repl
julia> JuDoc.matchrange(match(r"ell", "hello"))
2:4
```
"""
matchrange(m::RegexMatch)::UnitRange{Int} = m.offset .+ (0:(length(m.match)-1))

# Other convenience functions

"""
$(SIGNATURES)

Convenience function to display a time since `start`.
"""
function time_it_took(start::Float64)::Nothing
    comp_time = time() - start
    mess = comp_time > 60 ? "$(round(comp_time/60;   digits=1))m" :
           comp_time >  1 ? "$(round(comp_time;      digits=1))s" :
                            "$(round(comp_time*1000; digits=1))ms"
    println("[done $(lpad(mess, 6))]")
    return nothing
end


"""
$(SIGNATURES)

Convenience function to check if a variable is `nothing`. It is defined here to guarantee
compatibility with Julia 1.0 (the function exists for Julia ≥ 1.1).
"""
isnothing(x)::Bool = (x === nothing)


"""
$(SIGNATURES)

Convenience function to denote a string as being in a math context in a recursive parsing
situation. These blocks will be processed as math blocks but without adding KaTeX elements to it
given that they are part of a larger context that already has KaTeX elements.
NOTE: this happens when resolving latex commands in a math environment. So for instance if you have
`\$\$ x \\in \\R \$\$` and `\\R` is defined as a command that does `\\mathbb{R}` well that would be
an embedded math environment. These environments are marked as such so that we don't add additional
KaTeX markers around them.
"""
mathenv(s::AbstractString)::String = "_\$>_$(s)_\$<_"


"""
$(SIGNATURES)

Takes a string `s` and replace spaces by underscores so that that we can use it
for hyper-references. So for instance `"aa  bb"` will become `aa-bb`.
It also defensively removes any non-word character so for instance `"aa bb !"` will be `"aa-bb"`
"""
function refstring(s::AbstractString)::String
    # remove non-word characters
    st = replace(s, r"&#[0-9]+;" => "")
    st = replace(st, r"[^a-zA-Z0-9_\-\s]" => "")
    st = replace(lowercase(strip(st)), r"\s+" => "-")
    isempty(st) && return string(hash(s))
    return st
end


"""
$(SIGNATURES)

Internal function to take a unix path, split it along `/` and re-join it (which will lead to the
same path on unix but not on windows). Only used in [`resolve_assets_rpath`](@ref).
"""
joinrp(rpath::AbstractString) = joinpath(split(rpath, '/')...)

"""
$(SIGNATURES)

Internal function to resolve a relative path. See [`convert_code_block`](@ref) and
[`resolve_input`](@ref).
"""
function resolve_assets_rpath(rpath::AbstractString)::String
    @assert length(rpath) > 1 "relative path '$rpath' doesn't seem right"
    if startswith(rpath, "/")
        # this is a full path starting from the website root folder so for instance
        # `/assets/blah/img1.png`
        return normpath(joinpath(JD_PATHS[:f], joinrp(rpath[2:end])))
    elseif startswith(rpath, "./")
        # this is a path relative to the assets folder with the same path as the calling file so
        # for instance if calling from `src/pages/pg1.md` with `./im1.png` it would refer to
        # /assets/pages/im1.png
        @assert length(rpath) > 2 "relative path '$rpath' doesn't seem right"
        return normpath(joinpath(JD_PATHS[:assets], dirname(JD_CURPATH[]), joinrp(rpath[3:end])))
    end
    # this is a full path relative to the assets folder for instance `blah/img1.png` would
    # correspond to `/assets/blah/img1.png`
    return normpath(joinpath(JD_PATHS[:assets], joinrp(rpath)))
end
