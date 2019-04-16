const JD_CAN_PRERENDER = try success(`node -v`); catch; false; end
const JD_CAN_HIGHLIGHT = try success(`node -e "require('highlight.js')"`); catch;
                             false; end

const JD_HAS_PY3       = try success(`python3 -V`); catch; false; end
const JD_HAS_PIP3      = try success(`pip3 -V`); catch; false; end

const JD_CAN_MINIFY    = JD_HAS_PY3 && JD_HAS_PIP3 &&
                         try success(`python3 -m "import css_html_js_minify"`) ||
                             success(`pip3 install css_html_js_minify`); catch; false; end
