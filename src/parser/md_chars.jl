"""
$SIGNATURES

Take a list of token and return those corresponding to special characters or html entities wrapped
in `HTML_SPCH` types (will be left alone by the markdown conversion and be inserted as is in the
HTML).
"""
function find_special_chars(tokens::Vector{Token})
    spch = Vector{HTML_SPCH}()
    isempty(tokens) && return spch
    for τ in tokens
        τ.name == :CHAR_BACKSPACE   && push!(spch, HTML_SPCH(τ.ss, "&#92;"))
        τ.name == :CHAR_BACKTICK    && push!(spch, HTML_SPCH(τ.ss, "&#96;"))
        τ.name == :CHAR_LINEBREAK   && push!(spch, HTML_SPCH(τ.ss, "<br/>"))
        τ.name == :CHAR_HTML_ENTITY && verify_html_entity(τ.ss) && push!(spch, HTML_SPCH(τ.ss))
    end
    return spch
end

"""
$SIGNATURES

Verify that a given string corresponds to a well formed html entity.
"""
function verify_html_entity(ss::AbstractString)
    match(r"&(?:[a-z0-9]+|#[0-9]{1,6}|#x[0-9a-f]{1,6});", ss) !== nothing
end
