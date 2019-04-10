# This is a simple script using `css_html_js_minify` (available via pip) to compress html and css
# files (the js that we use is already compressed). This script takes negligible time to run.

import os
from css_html_js_minify import process_single_html_file as min_html
from css_html_js_minify import process_single_css_file as min_css

# modify those if you're not using the standard output paths.
CSS, PUB = "css/", "pub/"
min_html("index.html", overwrite=True)
for root, dirs, files in os.walk(PUB):
    for fname in files:
        if fname.endswith(".html"):
            min_html(os.path.join(root, fname), overwrite=True)

for root, dirs, files in os.walk(CSS):
    for fname in files:
        if fname.endswith(".css"):
            min_css(os.path.join(root, fname), overwrite=True)
