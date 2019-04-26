# JuDoc.jl - Documentation

JuDoc is a simple **static site generator** (SSG) oriented towards technical blogging (code, maths, ...) and light, fast-loading pages.
The base syntax is plain markdown with a few extensions such as the ability to define and use LaTeX-like commands in or outside of maths environments (see [Syntax](@ref)).


## Installation

With Julia ≥ 1.0,

```julia-repl
pkg> add https://github.com/tlienart/JuDoc.jl
```

### Dependencies

JuDoc allows a post-processing step which pre-renders highlighted code blocks and math environments and minifies all HTML and CSS.
This step requires a few dependencies; they are _not required_ to run JuDoc.

* [`node.js`](https://nodejs.org/en/) for the pre-rendering,
* [`python3`](https://www.python.org/downloads/) for the minification,
* [`git`](https://git-scm.com/downloads) for automating pushing and pulling to remote repository.

Assuming you have those, you will then need to install `highlight.js` via `npm`:

```bash
[sudo] npm install -g highlight.js
```

and the python package `css_html_js_minify` which you can install with `pip3`:

```bash
pip3 install css_html_js_minify
```

## Quick-start

Change directory to an appropriate sandbox location on your computer, start Julia and:

```julia-repl
julia> using JuDoc
julia> newsite("test", template="pure-sm")
✓ Website folder generated at test (now the current directory).
→ Use `serve()` from `JuDoc` to see the website in your browser.

julia> serve()
✓ LiveServer listening on http://localhost:8000/ ...
  (use CTRL+C to shut down)
```

This will generate a folder `test/` with overall structure:

```
.
├── assets/
├── css/
├── index.html
├── libs/
├── pub/
└── src
    ├── _css/
    ├── _html_parts/
    ├── config.md
    ├── index.md
    └── pages/
```

You can see what the corresponding website looks like by opening a browser at the given address `http://localhost:8000`.
If you modify the content (e.g. `src/index.md`), the modifications will be live-rendered immediately in your browser.
Modifying `src/index.md` will also be a great way to get familiar with the syntax and get a feel for what can be done with JuDoc.

### Folder structure

You should ignore the `css/` and `pub/` folders as well as the `index.html` file.
Those are _generated_ (and should thus not be modified).

The `assets/` and `libs/` folder are secondary, `assets/` might contain images or scripts you want to display and `libs/` will contain javascript libraries that may be needed by your website.

Finally, the key folder is `src/` which contains the effective source that generates the website; this is where modifications should be made.

* `_css/` contains the CSS style sheets
* `_html_parts/` contains the html bits that go around your content (e.g. the header, footer or navigation bar)
* `config.md` is the configuration file for your website, it defines variables and commands that can be used by all pages
* `index.md` is the source for the `index.html` page


!!! note

    In some circumstances you may want to style your `index.html` separately; in that case, remove the `index.md` and write your own `index.html` instead (still in `src/`). You can still use variables in it if you wish.
