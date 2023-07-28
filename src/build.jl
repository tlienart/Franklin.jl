function PY()
    if "PYTHON3" ∈ keys(ENV)
        ENV["PYTHON3"]
    else
        if Sys.iswindows()
            if "PYENV" ∈ keys(ENV)
                return "python"
            end
            "py -3"
        else
            "python3"
        end
    end
end
function PIP()
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
function NODE()
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
function FD_CAN_PRERENDER()
    r = shell_try(`$(NODE()) -v`)
    if !r
        @warn """Couldn't find node.js: `$(NODE()) -v` failed. Setting `prerender=false`.

        Note: node is required for pre-rendering KaTeX and highlight.js, but it is not necessary to run Franklin (cf docs)."""
    end
    return r
end
let r = nothing # Hack to only run the checks once per call to Franklin.optimize since this is called multiple times
    global function FD_CAN_HIGHLIGHT(; force::Bool=false)
        if force || r === nothing
            r = FD_CAN_PRERENDER() && shell_try(`$(NODE()) -e "require('$(HIGHLIGHTJS[])')"`)
            if !r
                @warn """Couldn't find highlight.js: `$(NODE()) -e "require('$(HIGHLIGHTJS[])')"` failed. Will not prerender code blocks.

                Note: highlight.js is required for pre-rendering highlight.js, but is not necessary to run Franklin (cf docs)."""
            end
        end
        return r
    end
end

#=
Minification
- We use `css_html_js_minify`. To use it, you need python3 and to install it.
- Here we check there is python3, and pip3, and then if we fail to import, we try to
use pip3 to install it.
=#
function FD_HAS_PY3()
    r = shell_try(`$([e for e in split(PY())]) -V`)
    if !r
        @warn """Couldn't find python3 (`$([e for e in split(PY())]) -V` failed). Will not minify.

        Note: python3 is required for minification, but not necessary to run Franklin (cf docs)."""
    end
    return r
end
FD_HAS_PIP3() = shell_try(`$([e for e in split(PIP())]) -V`)

