# JuDoc.jl - Documentation

JuDoc is a simple **static site generator** (SSG) oriented towards technical blogging (code, maths, ...) with light, fast-loading pages.
The base syntax is plain markdown but also supports the definition of LaTeX-like commands and their use in or outside of maths environments.



## Installation

With Julia ≥ 1.0,

```julia-repl
pkg> add https://github.com/tlienart/JuDoc.jl
```

### Dependencies

JuDoc allows a post-processing step which pre-renders highlighted code blocks and math environments and minifies all HTML and CSS.
This step requires a few dependencies; they **not required** to run JuDoc but are recommended.

* [`node.js`](https://nodejs.org/en/) for the pre-rendering
* [`python3`](https://www.python.org/downloads/) for the minification

Assuming you have those, you will need to install `highlight.js` via `npm`:

```bash
[sudo] npm install -g highlight.js
```

and `css_html_js_minify`

You can test your setup in Julia by running

```julia-repl
julia> success(`node -v`)
true
julia> success(`python3 -V`) # capital V
true
```



## Usage
