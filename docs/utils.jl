using Markdown

function lx_escape(com, _)
    # keep this first line
    content = Franklin.content(com.braces[1]) # input string
    lang, code = split(content, "::")
    scode = strip(code)
    esc_code = Markdown.htmlesc(scode)
    io = IOBuffer()
    println(io, "```$lang")
    println(io, esc_code)
    println(io, "```")
    return String(take!(io))
end
