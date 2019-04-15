
# if the user has node, pre-rendering can be done
const JD_HAS_NODE = try success(`node -v`); catch; false; end

#  if the user has `css_html_js_minify` then can minify in publish
const JD_HAS_MINIFY = try success(`python -c "import css_html_js_minify"`); catch; false; end
