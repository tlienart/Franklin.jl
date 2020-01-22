"""
$(SIGNATURES)

Convenience function to add an id attribute to a html element
"""
attr(name::Symbol, val::AS) = ifelse(isempty(val), "", " $name=\"$val\"")

"""
$SIGNATURES

Convenience function for a sup item
"""
html_sup(id::String, in::AS) =  "<sup id=\"$id\">$in</sup>"

"""
$(SIGNATURES)

Convenience function for a header
"""
html_hk(hk::String, header::AS; id::String="") = "<$hk$(attr(:id, id))>$header</$hk>"

"""
$(SIGNATURES)

Convenience function to introduce a hyper reference.
"""
function html_ahref(link::AS, name::Union{Int,AS};
                    title::AS="", class::AS="")
    a  = "<a href=\"$(htmlesc(link))\""
    a *= attr(:title, title)
    a *= attr(:class, class)
    a *= ">$name</a>"
    a
end

"""
$(SIGNATURES)

Convenience function to introduce a hyper reference relative to a key (local hyperref).
"""
function html_ahref_key(key::AS, name::Union{Int,AS})
    return html_ahref(url_curpage() * "#$key", name)
end

"""
$(SIGNATURES)

Convenience function to introduce a div block.
"""
html_div(name::AS, in::AS) = "<div class=\"$name\">$in</div>"

"""
$(SIGNATURES)

Convenience function to introduce an image. The alt is escaped just in case the user adds quotation
marks in the alt string.
"""
html_img(src::AS, alt::AS="") = "<img src=\"$src\" alt=\"$(htmlesc(alt))\">"

"""
$(SIGNATURES)

Convenience function to introduce a code block.
"""
function html_code(c::AS, lang::AS="")
    isempty(c)     && return ""
    isempty(lang)  && return "<pre><code class=\"plaintext\">$c</code></pre>"
    lang == "html" && !is_html_escaped(c) && (c = htmlesc(c))
    return "<pre><code class=\"language-$lang\">$c</code></pre>"
end

"""
$(SIGNATURES)

Convenience function to introduce inline code.
"""
html_code_inline(c::AS) = "<code>$c</code>"

"""
$(SIGNATURES)

Insertion of a visible red message in HTML to show there was a problem.
"""
html_err(mess::String="") = "<p><span style=\"color:red;\">// $mess //</span></p>"

"""
$(SIGNATURES)

Helper function to get the relative url of the current page.
"""
function url_curpage()
    # go from /pages/.../something.md to /pub/.../something.html note that if
    # on windows then it would be \\ whence the PATH_SEP
    rp = replace(FD_ENV[:CUR_PATH], Regex("^pages$(escape_string(PATH_SEP))")=>"pub$(PATH_SEP)")
    rp = unixify(rp)
    rp = splitext(rp)[1] * ".html"
    startswith(rp, "/") || (rp = "/" * rp)
    return rp
end

# Copied from https://github.com/JuliaLang/julia/blob/acb7bd93fb2d5adbbabeaed9f39ab3c85495b02f/stdlib/Markdown/src/render/html.jl#L25-L31
const _htmlescape_chars = LittleDict(
            '<' => "&lt;",
            '>' => "&gt;",
            '"' => "&quot;",
            '&' => "&amp;"
            )
for ch in "'`!\$%()=+{}[]"
    _htmlescape_chars[ch] = "&#$(Int(ch));"
end

const _htmlesc_to = values(_htmlescape_chars) |> collect

"""
$(SIGNATURES)

Internal function to check if some html code has been escaped.
"""
is_html_escaped(cs::AS) = !isnothing(findfirst(ss -> occursin(ss, cs), _htmlesc_to))

"""
$(SIGNATURES)

Internal function to reverse the escaping of some html code (in order to avoid
double escaping when pre-rendering with highlight, see issue 326).
"""
function html_unescape(cs::String)
    # this is a bit inefficient but whatever, `cs` shouldn't  be very long.
    for (ssfrom, ssto) in _htmlescape_chars
        cs = replace(cs, ssto => ssfrom)
    end
    return cs
end
