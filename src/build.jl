#=
Pre-rendering
- In order to prerender KaTeX, the only thing that is required is `node` and then we can just
require `katex.min.js`
- For highlights, we need `node` and also to have the `highlight.js` installed via `npm`.
=#
const JD_CAN_PRERENDER = try success(`node -v`); catch; false; end
const JD_CAN_HIGHLIGHT = try success(`node -e "require('highlight.js')"`); catch;
                             false; end

#=
Minification
- We use `css_html_js_minify`. To use it, you need python3 and to install it.
- Here we check there is python3, and pip3, and then if we fail to import, we try to
use pip3 to install it.
=#
const JD_HAS_PY3    = try success(`python3 -V`); catch; false; end
const JD_HAS_PIP3   = try success(`pip3 -V`); catch; false; end
const JD_CAN_MINIFY = JD_HAS_PY3 && JD_HAS_PIP3 &&
                      try success(`python3 -m "import css_html_js_minify"`) ||
                          success(`pip3 install css_html_js_minify`); catch; false; end

#=
Information to the user
- what JuDoc couldn't find
- that the user should do a `build` step after installing
=#
JD_CAN_HIGHLIGHT || begin
    JD_CAN_PRERENDER || begin
        println("""✘ Couldn't find node.js (`node -v` failed).
                → It is required for pre-rendering KaTeX and highlight.js but is not necessary to run JuDoc (cf docs).""")
    end
    println("""✘ Couldn't find highlight.js (`node -e "require('highlight.js')"` failed).
            → It is required for pre-rendering highlight.js but is not necessary to run JuDoc (cf docs).""")
end

JD_CAN_MINIFY || begin
    if JD_HAS_PY3
        println("✘ Couldn't find css_html_js_minify (`python3 -m \"import css_html_js_minify\"` " *
                "failed).\n" *
                """→ It is required for minification but is not necessary to run JuDoc (cf docs).""")
    else
        println("""✘ Couldn't find python3 (`python3 -V` failed).
                → It is required for minification but not necessary to run JuDoc (cf docs).""")
    end
end

all((JD_CAN_HIGHLIGHT, JD_CAN_PRERENDER, JD_CAN_MINIFY, JD_HAS_PY3, JD_HAS_PIP3)) || begin
    println("→ After installing any missing component, please re-build the package (cf docs).")
end
