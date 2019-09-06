"""
$(SIGNATURES)

Convenience function to introduce a hyper reference.
"""
html_ahref(link::AbstractString, name::Union{Int,AbstractString}; title::AbstractString="") =
    "<a href=\"$link\"$(isempty(title) ? "" : "title=\"$(Markdown.htmlesc(title))\"")>$name</a>"

"""
$(SIGNATURES)

Convenience function to introduce a hyper reference relative to a key (local hyperref).
"""
html_ahref_key(key::AbstractString, name::Union{Int,AbstractString}) = html_ahref("#$key", name)

"""
$(SIGNATURES)

Convenience function to introduce a div block.
"""
html_div(name::AbstractString, in::AbstractString) = "<div class=\"$name\">$in</div>"

"""
$(SIGNATURES)

Convenience function to introduce an image. The alt is escaped just in case the user adds quotation
marks in the alt string.
"""
html_img(src::AbstractString, alt::AbstractString="") =
    "<img src=\"$src\" alt=\"$(Markdown.htmlesc(alt))\">"

"""
$(SIGNATURES)

Convenience function to introduce an image.
"""
function html_code(c::AbstractString, lang::AbstractString="")
    isempty(c) && return ""
    isempty(lang) && return "<pre><code>$c</code></pre>"
    return "<pre><code class=\"language-$lang\">$c</code></pre>"
end

"""
$(SIGNATURES)

Insertion of a visible red message in HTML to show there was a problem.
"""
html_err(mess::String="") = "<p><span style=\"color:red;\">// $mess //</span></p>"
