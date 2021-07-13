const PY = begin
    if "PYTHON3" ∈ keys(ENV)
        ENV["PYTHON3"]
    else
        if Sys.iswindows()
            "py -3"
        else
            "python3"
        end
    end
end
const PIP = begin
    if "PIP3" ∈ keys(ENV)
        ENV["PIP3"]
    else
        if Sys.iswindows()
            "py -3 -m pip"
        else
            "pip3"
        end
    end
end
const NODE = begin
    if "NODE" ∈ keys(ENV)
        ENV["NODE"]
    else
        NodeJS.nodejs_cmd()
    end
end

# highligh.js library; can be overridden from the outside which is useful for testing
const HIGHLIGHTJS = Ref{String}("highlight.js")

shell_try(com)::Bool = try success(com); catch; false; end

#=
Pre-rendering
- In order to prerender KaTeX, the only thing that is required is `node` and then we can just
require `katex.min.js`
- For highlights, we need `node` and also to have the `highlight.js` installed via `npm`.
=#
const FD_CAN_PRERENDER = shell_try(`$NODE -v`)
const FD_CAN_HIGHLIGHT = shell_try(`$NODE -e "require('$(HIGHLIGHTJS[])')"`)

#=
Minification
- We use `css_html_js_minify`. To use it, you need python3 and to install it.
- Here we check there is python3, and pip3, and then if we fail to import, we try to
use pip3 to install it.
=#
const FD_HAS_PY3    = shell_try(`$([e for e in split(PY)]) -V`)
const FD_HAS_PIP3   = shell_try(`$([e for e in split(PIP)]) -V`)
const FD_CAN_MINIFY = FD_HAS_PY3 && FD_HAS_PIP3 &&
        (success(`$([e for e in split(PY)]) -c "import css_html_js_minify"`) ||
         success(`$([e for e in split(PIP)]) install css_html_js_minify`))
#=
Information to the user
- what Franklin couldn't find
- that the user should do a `build` step after installing
=#
FD_CAN_HIGHLIGHT || begin
    FD_CAN_PRERENDER || begin
        println("""✘ Couldn't find node.js (`$NODE -v` failed).
                → It is required for pre-rendering KaTeX and highlight.js but is not necessary to run Franklin (cf docs).""")
    end
    println("""✘ Couldn't find highlight.js (`$NODE -e "require('$(HIGHLIGHTJS[])')"` failed).
            → It is required for pre-rendering highlight.js but is not necessary to run Franklin (cf docs).""")
end

FD_CAN_MINIFY || begin
    if FD_HAS_PY3
        println("✘ Couldn't find css_html_js_minify (`$([e for e in split(PY)]) -m \"import css_html_js_minify\"` failed).\n" *
                """→ It is required for minification but is not necessary to run Franklin (cf docs).""")
    else
        println("""✘ Couldn't find python3 (`$([e for e in split(PY)]) -V` failed).
                → It is required for minification but not necessary to run Franklin (cf docs).""")
    end
end

all((FD_CAN_HIGHLIGHT, FD_CAN_PRERENDER, FD_CAN_MINIFY, FD_HAS_PY3, FD_HAS_PIP3)) || begin
    println("→ After installing any missing component, please re-build the package (cf docs).")
end
