#= =========================
Dicts for hyper references
============================ =#

"""
    JD_LOC_EQDICT

Dictionary to keep track of equations that are labelled on a page to allow
references within the page.
"""
const JD_LOC_EQDICT = Dict{String, Int}()


"""
    JD_LOC_EQDICT_COUNTER

Counter to keep track of equation numbers as they appear along the page, this
helps with equation referencing.
"""
const JD_LOC_EQDICT_COUNTER = randstring(JD_LEN_RANDSTRING+1)

def_JD_LOC_EQDICT() = begin
    empty!(JD_LOC_EQDICT)
    JD_LOC_EQDICT[JD_LOC_EQDICT_COUNTER] = 0
end


"""
    JD_LOC_BIBREFDICT

Dictionary to keep track of bibliographical references on a page to allow
citation within the page
"""
const JD_LOC_BIBREFDICT = Dict{String, String}()

def_JD_LOC_BIBREFDICT() = empty!(JD_LOC_BIBREFDICT)


"""
    form_biblabel(lxc)

Given a `biblabel` command, update `JD_LOC_BIBREFDICT` to keep track of the
reference so that it can be linked with a hyperreference.
"""
function form_biblabel(λ::LxCom)
    name = refstring(strip(content(λ.braces[1])))
    JD_LOC_BIBREFDICT[name] = content(λ.braces[2])
    return "<a id=\"$name\"></a>"
end


"""
    form_href(lxc, d)

Given a latex command such as `\\eqref{abc}`, hash the reference (here `abc`),
check if the given dictionary `d` has an entry corresponding to that hash
and return the appropriate HTML for it.
"""
function form_href(lxc::LxCom, dname::String; parens="("=>")", class="href")

    ct = content(lxc.braces[1]) # "r1, r2, r3"
    refs = strip.(split(ct, ","))    # ["r1", "r2", "r3"]
    names = refstring.(refs)
    nkeys = length(names)
    # construct the partial link with appropriate parens, it will be
    # resolved at the second pass (HTML pass) whence the introduction of {{..}}
    # inner will be "{{href $dn $hr1}}, {{href $dn $hr2}}, {{href $dn $hr3}}"
    # where $hr1 is the hash of r1 etc.
    in = prod("{{href $dname $name}}$(ifelse(i < nkeys, ", ", ""))"
                    for (i, name) ∈ enumerate(names))
    # encapsulate in a span for potential css-styling
    return "<span class=\"$class\">$(parens.first)$in$(parens.second)</span>"
end


"""
    JD_REF_COMS

Dictionary for latex commands related to hyperreference for which a specific
replacement that depends on context is constructed.
"""
const JD_REF_COMS = Dict{String, Function}(
    "\\eqref"    => (λ -> form_href(λ, "EQR";  class="eqref")),
    "\\cite"     => (λ -> form_href(λ, "BIBR"; parens=""=>"", class="bibref")),
    "\\citet"    => (λ -> form_href(λ, "BIBR"; parens=""=>"", class="bibref")),
    "\\citep"    => (λ -> form_href(λ, "BIBR"; class="bibref")),
    "\\biblabel" => form_biblabel,
)
