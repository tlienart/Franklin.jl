"""
    html_href(key, name)

Convenience function to introduce a hyper reference.
"""
html_ahref(key, name) = "<a href=\"#$key\">$name</a>"


"""
    html_div(cname, content)

Convenience function to introduce a div block.
"""
html_div(cname, content) = "<div class=\"$cname\">$content</div>\n"
