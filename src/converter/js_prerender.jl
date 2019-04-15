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

function js_prerender_math2(hs::AbstractString)
    # look for \(, \[, \], \)
    matches = collect(eachmatch(r"\\(\(|\[|\]|\))", hs))

    @show matches

    jsbuffer = IOBuffer()
    write(jsbuffer, """
            var katex = require("$(joinpath(JD_PATHS[:libs], "katex", "katex.min.js"))")
            """)

    splitter = "_>jdsplit<_"
    for i ∈ 1:2:length(matches)-1
        mo, mc = matches[i:i+1]
        display = (mo.match == "\\[")
        ms = subs(hs, mo.offset + 2, mc.offset - 1)
        write(jsbuffer, """
            var html = katex.renderToString("$(escape_string(ms))", {displayMode: $display})
            console.log(html)
            """)
        i == length(matches)-1 || write(jsbuffer, """\nconsole.log("$splitter")\n""")
    end
#    outf = tempname()
    outf = "/Users/tlienart/Desktop/script.js"
    write(outf, take!(jsbuffer))
    outbuffer = IOBuffer()
    run(pipeline(`node $outf`, stdout=outbuffer))

    out = String(take!(outbuffer))
    kx_parts = split(out, splitter)

    # lace everything back together
    htmlbuffer = IOBuffer()
    head = 1
    c = 1
    for i ∈ 1:2:length(matches)-1
        mo, mc = matches[i:i+1]
        write(htmlbuffer, subs(hs, head, mo.offset - 1))
        write(htmlbuffer, kx_parts[c])
        head = mc.offset + 2
        c += 1
    end
    head < lastindex(hs) && write(htmlbuffer, subs(hs, head, lastindex(hs)))
    return String(take!(htmlbuffer))
end
