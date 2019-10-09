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
    isempty(c) && return ""
    isempty(lang) && return "<pre><code class=\"plaintext\">$c</code></pre>"
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
    rp = replace(CUR_PATH[], Regex("^pages$(escape_string(PATH_SEP))")=>"pub$(PATH_SEP)")
    rp = unixify(rp)
    rp = splitext(rp)[1] * ".html"
    startswith(rp, "/") || (rp = "/" * rp)
    return rp
end
