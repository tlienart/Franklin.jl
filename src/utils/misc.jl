"""
$SIGNATURES

Specify the folder for the Literate scripts, by default this is `scripts/`.
"""
function literate_folder(rp::String="")
    isempty(rp) && return PATHS[:literate]
    path = joinpath(PATHS[:folder], rp)
    !isdir(path) && error("Specified Literate path not found ($rp -- $path)")
    PATHS[:literate] = path
    return path
end

#
# Convenience functions to work with strings and substrings
#

"""
$(SIGNATURES)

Returns the string corresponding to `s`: `s` itself if it is a string, or the
parent string if `s` is a substring. Do not confuse with `String(s::SubString)`
which casts `s` into its own object.

# Example

```julia-repl
julia> a = SubString("hello Fraknlin", 3:8);
julia> Franklin.str(a)
"hello Franklin"
julia> String(a)
"llo Fr"
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
julia> Franklin.subs("hello", 2:4)
"ell"
```
"""
subs(s::AS, from::Int, to::Int)::SubString    = SubString(s, from, to)
subs(s::AS, from::Int)::SubString             = subs(s, from, from)
subs(s::AS, range::UnitRange{Int})::SubString = SubString(s, range)
subs(s::AS) = SubString(s)

"""
$(SIGNATURES)

Given a substring `ss`, returns the position in the parent string where the substring starts.

# Example
```julia-repl
julia> ss = SubString("hello", 2:4); Franklin.from(ss)
2
```
"""
from(ss::SubString)::Int = nextind(str(ss), ss.offset)
from(s::String) = 1

"""
$(SIGNATURES)

Given a substring `ss`, returns the position in the parent string where the substring ends.

# Example
```julia-repl
julia> ss = SubString("hello", 2:4); Franklin.to(ss)
4
```
"""
to(ss::SubString)::Int = ss.offset + ss.ncodeunits
to(s::String) = lastindex(s)

"""
$(SIGNATURES)

Returns the string span of a regex match. Assumes there is no unicode in the match.

# Example
```julia-repl
julia> Franklin.matchrange(match(r"ell", "hello"))
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
function print_final(startmsg::AS, starttime::Float64)::Nothing
    tit = time_it_took(starttime)
    rprint("$startmsg$tit")
    print("\n")
end


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
mathenv(s::AS)::String = "_\$>_$(s)_\$<_"


"""
$(SIGNATURES)

Takes a string `s` and replace spaces by underscores so that that we can use it
for hyper-references. So for instance `"aa  bb"` will become `aa_bb`.
It also defensively removes any non-word character so for instance `"aa bb !"` will be `"aa_bb"`
"""
function refstring(s::AS)::String
    # remove html tags
    st = replace(s, r"<[a-z\/]+>"=>"")
    # remove non-word characters
    st = replace(st, r"&#[0-9]+;" => "")
    st = replace(st, r"[^a-zA-Z0-9_\-\s]" => "")
    # replace spaces by dashes
    st = replace(lowercase(strip(st)), r"\s+" => "_")
    # to avoid clashes with numbering of repeated headers, replace
    # double underscores by a single one (see convert_header function)
    st = replace(st, r"__" => "_")
    # in the unlikely event we don't have anything here, return the hash
    # of the original string
    isempty(st) && return string(hash(s))
    return st
end

"""
context(parent, position)

Return an informative message of the context of a position and where the
position is, this is useful when throwing error messages.
"""
function context(par::AS, pos::Int)
    # context string
    lidx = lastindex(par)
    if pos > 20
        head = max(1, prevind(par, pos-20))
    else
        head = 1
    end
    if pos <= lidx-20
        tail = min(lidx, nextind(par, pos+20))
    else
        tail = lidx
    end
    prepend  = ifelse(head > 1, "...", "")
    postpend = ifelse(tail < lidx, "...", "")

    ctxt = prepend * subs(par, head, tail) * postpend

    # line number
    lines  = split(par, "\n", keepempty=false)
    nlines = length(lines)
    ranges = zeros(Int, nlines, 2)
    cs = 0
    for (i, l) in enumerate(lines[1:end-1])
        tmp = [nextind(par, cs), nextind(par, lastindex(l) + cs)]
        ranges[i, :] .= tmp
        cs = tmp[2]
    end
    ranges[end, :] = [nextind(par, cs), lidx]

    lno = findfirst(i -> ranges[i,1] <= pos <= ranges[i,2], 1:nlines)

    # Assemble to form a message
    mess = """
    Context:
    \t$(strip(ctxt)) (near line $lno)
    \t$(" "^(pos-head+length(prepend)))^---
    """
    return mess
end
