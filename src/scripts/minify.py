# This is a simple script using `css_html_js_minify` (available via pip)
# to compress html and css files (the js that we use is already compressed).
# This script takes negligible time to run.

import os
from css_html_js_minify import process_single_html_file as min_html
from css_html_js_minify import process_single_css_file as min_css

# modify those if you're not using the standard output paths.
html_files = []
css_files = []
for root, dirs, files in os.walk("__site"):
    for fname in files:
        path = os.path.join(root, fname)
        # skip the assets folder which should be left untouched (#568)
        if path.startswith(os.path.join("__site", "assets")):
            continue
        if fname.endswith(".html"):
            html_files.append(os.path.join(root, fname))
        if fname.endswith(".css"):
            css_files.append(os.path.join(root, fname))


css_files = [cf for cf in css_files if not cf.endswith(".min.css")]

for file in html_files:
    min_html(file, overwrite=True)
for file in css_files:
    min_css(file, overwrite=True)
