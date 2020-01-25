"""
PAGE_EQREFS

Dictionary to keep track of equations that are labelled on a page to allow
references within the page.
"""
const PAGE_EQREFS = LittleDict{String, Int}()

"""
PAGE_EQREFS_COUNTER

Counter to keep track of equation numbers as they appear along the page, this
helps with equation referencing. (The `_XC0q` is just a random string to avoid
clashes).
"""
const PAGE_EQREFS_COUNTER = "COUNTER_XC0q"

"""
$(SIGNATURES)

Reset the PAGE_EQREFS dictionary.
"""
@inline function def_PAGE_EQREFS!()
    empty!(PAGE_EQREFS)
    PAGE_EQREFS[PAGE_EQREFS_COUNTER] = 0
    return nothing
end

"""
PAGE_BIBREFS

Dictionary to keep track of bibliographical references on a page to allow
citation within the page.
"""
const PAGE_BIBREFS = LittleDict{String, String}()

"""
$(SIGNATURES)

Reset the PAGE_BIBREFS dictionary.
"""
def_PAGE_BIBREFS!() = (empty!(PAGE_BIBREFS); nothing)


"""
$(SIGNATURES)

Given a latex command such as `\\eqref{abc}`, hash the reference (here `abc`),
check if the given dictionary `d` has an entry corresponding to that hash and
return the appropriate HTML for it.
"""
function form_href(lxc::LxCom, dname::String;
                   parens="("=>")", class="href")::String
    cont  = content(lxc.braces[1])   # "r1, r2, r3"
    refs  = strip.(split(cont, ",")) # ["r1", "r2", "r3"]
    names = refstring.(refs)
    nkeys = length(names)
    # construct the partial link with appropriate parens, it will be
    # resolved at the second pass (HTML pass) whence the introduction of {{..}}
    # inner will be "{{href $dn $hr1}}, {{href $dn $hr2}}, {{href $dn $hr3}}"
    # where $hr1 is the hash of r1 etc.
    inner = prod("{{href $dname $name}}$(ifelse(i < nkeys, ", ", ""))"
                    for (i, name) ∈ enumerate(names))
    # encapsulate in a span for potential css-styling
    return html_span(class, parens.first * inner * parens.second)
end

lx_eqref(λ::LxCom) = form_href(λ, "EQR";  class="eqref")
lx_cite(λ::LxCom)  = form_href(λ, "BIBR"; parens=""=>"", class="bibref")
lx_citet(λ::LxCom) = form_href(λ, "BIBR"; parens=""=>"", class="bibref")
lx_citep(λ::LxCom) = form_href(λ, "BIBR"; class="bibref")

function lx_label(λ::LxCom)
    refs = content(λ.braces[1]) |> strip |> refstring
    return "<a id=\"$refs\"></a>"
end

function lx_biblabel(λ::LxCom)::String
    name = refstring(strip(content(λ.braces[1])))
    PAGE_BIBREFS[name] = content(λ.braces[2])
    return "<a id=\"$name\"></a>"
end

function lx_toc(::LxCom)
    minlevel = LOCAL_VARS["mintoclevel"].first
    maxlevel = LOCAL_VARS["maxtoclevel"].first
    return "{{toc $minlevel $maxlevel}}"
end
