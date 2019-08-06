
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
    subs(s)

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
subs(s::AbstractString) = SubString(s)

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
function time_it_took(start::Float64)
    comp_time = time() - start
    mess = comp_time > 60 ? "$(round(comp_time/60;   digits=1))m" :
           comp_time >  1 ? "$(round(comp_time;      digits=1))s" :
                            "$(round(comp_time*1000; digits=1))ms"
    return "[done $(lpad(mess, 6))]"
end

```
$(SIGNATURES)

Nicer printing of processes.
```
function print_final(startmsg::AbstractString, starttime::Float64)::Nothing
    tit = time_it_took(starttime)
    println("\r$startmsg$tit")
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
for hyper-references. So for instance `"aa  bb"` will become `aa_bb`.
It also defensively removes any non-word character so for instance `"aa bb !"` will be `"aa_bb"`
"""
function refstring(s::AbstractString)::String
    # remove html tags
    st = replace(s, r"<[a-z\/]+>"=>"")
    # remove non-word characters
    st = replace(st, r"&#[0-9]+;" => "")
    st = replace(st, r"[^a-zA-Z0-9_\-\s]" => "")
    # replace spaces by dashes
    st = replace(lowercase(strip(st)), r"\s+" => "_")
    # in unlikely event we don't have anything here, return the hash of orig string
    isempty(st) && return string(hash(s))
    return st
end


"""
$(SIGNATURES)

Internal function to take a path and return a unix version of the path (if it isn't already).
Used in [`resolve_assets_rpath`](@ref).
"""
function unixify(rp::String)::String
    cand = Sys.isunix() ? rp : replace(rp, "\\"=>"/")
    isempty(splitext(cand)[2]) || return cand
    endswith(cand, "/") || isempty(cand) || return cand * "/"
    return cand
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
[`resolve_lx_input`](@ref).
As an example, let's say you have the path `./blah/blih.txt` somewhere in `src/pages/page1.md`.
The `./` indicates that the path should be reproduced in `/assets/` and so it will lead to
`/assets/pages/blah/blih.txt`.
In the `canonical=false` mode, the returned path is a UNIX path (irrelevant of your platform);
these paths can be given to html anchors (refs, img, ...).
In the `canonical=true` mode, the path is a valid path on the local system. These paths can be
given to Julia to read or write things.
"""
function resolve_assets_rpath(rpath::AbstractString; canonical::Bool=false)::String
    @assert length(rpath) > 1 "relative path '$rpath' doesn't seem right"
    if startswith(rpath, "/")
        # this is a full path starting from the website root folder so for instance
        # `/assets/blah/img1.png`; just return that
        canonical || return rpath
        return normpath(joinpath(PATHS[:folder], joinrp(rpath[2:end])))
    elseif startswith(rpath, "./")
        # this is a path relative to the assets folder with the same path as the calling file so
        # for instance if calling from `src/pages/pg1.md` with `./im1.png` it would refer to
        # /assets/pages/im1.png
        @assert length(rpath) > 2 "relative path '$rpath' doesn't seem right"
        canonical || return "/assets/" * unixify(dirname(CUR_PATH[])) * rpath[3:end]
        return normpath(joinpath(PATHS[:assets], dirname(CUR_PATH[]), joinrp(rpath[3:end])))
    end
    # this is a full path relative to the assets folder for instance `blah/img1.png` would
    # correspond to `/assets/blah/img1.png`
    canonical || return "/assets/" * rpath
    return normpath(joinpath(PATHS[:assets], joinrp(rpath)))
end
