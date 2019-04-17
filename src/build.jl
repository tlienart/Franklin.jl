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
