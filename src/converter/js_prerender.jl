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
    # everything was generated so is nicely paired (and not nested)
    i_open  = [m.offset for m ∈ eachmatch(r"\\\(", hs)]
    i_close = [m.offset for m ∈ eachmatch(r"\\\)", hs)]
    d_open  = [m.offset for m ∈ eachmatch(r"\\\[", hs)]
    d_close = [m.offset for m ∈ eachmatch(r"\\\]", hs)]

    # offsetstart - offsetstop - inline
    ranges = Vector{Tuple{Int, Int, Bool}}()

    idx_i = 1
    idx_d = 1

    while idx_i ≤ length(i_open) || idx_d ≤ length(d_open)
        # inline or display next?
        inline_next = i_open[idx_i] < d_open[idx_d]
        if inline_next
            push!(ranges, (i_open[idx_i], i_close[idx_i], true))
            idx_i += 1
        else
            push!(ranges, (d_open[idx_d], d_close[idx_d], false))
            idx_d += 1
        end
    end

    # for inline, need to go content (offset+2, offset-1) and out (:offset-1, offset+2:)
    # if the indices are valid for the out part (should always be the case but still check)

    # 1) Form Javascript
    # 2) Run Javascript with a splitter
    # 3) Split output
    # 4) re-construct HTML

end
