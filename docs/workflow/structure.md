<!--
reviewed: 18/4/20
-->

# Page structure


\blurb{Pages are assembled like lego blocks.}

<!-- \lineskip

\toc -->

## Overview

At a high level, the process to go from a markdown file `file.md` to the corresponding html page is quite simple:

```plaintext
result = head * body * page_foot * foot
```

where

* `head` corresponds to  `_layout/head.html`,
* `page_foot` and `foot` correspond respectively to  `_layout/page_foot.html` and `_layout/foot.html`,
* `body` correspond to Franklin's conversion of input markdown.

One additional step processes the resulting HTML to resolve any html function (`{{ ... }}`) that may be left.

The final HTML for a page will essentially look like:

```html
<!-- head.html -->
<!doctype html>
<html>
  <head>
    ...
  </head>
  <body>

<!-- ...
  resolved body + page foot
... -->

<!-- foot -->
  ...
  </body>
</html>  
```

Of course, it will depend on what you have in your `_layout/head.html` etc, you can tweak this at will. You can also make this as modular as you want by using conditional blocks in your `head.html` and inserting specific sub layouts depending on the page. For instance, the `head.html` file could include something like

```html
<!-- standard stuff -->
{{ispage blog/*}} {{insert head_blog}}{{end}}
<!-- ... -->
```

for more on this, see the section on [page variables](/syntax/page-variables/).

\note{This also means that it is required to have a `_layout/head.html`, `_layout/foot.html` and `_layout/page_foot.html`, you **must** have these files but they can be empty (in practice it wouldn't make sense to have all of them be empty but you could have `page_foot` empty).}

### Resolved body

The resolved body is plugged into a "container" div

```html
<div class="franklin-content">
...
</div>
```

if you're using a CSS framework like bootstrap, you might want to control the name of that outer div which you can do by specifying `@def div_content = "container"` in your `config.md`.
