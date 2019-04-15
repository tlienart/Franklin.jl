function js_prerender_math(ms::AbstractString; display::Bool=true)

    # STEPS
    # 1) construct javascript bits by bits
    # 2) send it to node
    # 3) recuperate STDOUT in a buffer and split it along given symbols

    jsbuffer = IOBuffer()
    write(jsbuffer, """
            var katex = require("$(joinpath(JD_PATHS[:libs], "katex", "katex.min.js"))")
            var html = katex.renderToString("$(escape_string(ms))", {displayMode: $display})
            console.log(html)
            """)
    # NOTE write to a temp file
    write("/Users/tlienart/Desktop/script.js", take!(jsbuffer))

    outbuffer = IOBuffer()
    p = pipeline(`node /Users/tlienart/Desktop/script.js`, stdout=outbuffer)
    s = success(p)

    s || println("no success")

    return String(take!(outbuffer))
    # NOTE remove script.js
end
