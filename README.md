# JuDoc

| Status | Coverage |
| :----: | :----: |
| [![Build Status](https://travis-ci.org/tlienart/JuDoc.jl.svg?branch=master)](https://travis-ci.org/tlienart/JuDoc.jl) | [![codecov.io](http://codecov.io/github/tlienart/JuDoc.jl/coverage.svg?branch=master)](http://codecov.io/github/tlienart/JuDoc.jl?branch=master) |

JuDoc is a simple **static site generator** (SSG) oriented towards technical blogging (code, maths, ...) and written in Julia.
The base syntax is markdown but it allows a subset of LaTeX (`\newcommand...`) and uses KaTeX to render the maths.
I use it to generate [my website](https://tlienart.github.io).

### Quick demo

(_for more detailed instructions, read the Install section further on_)

Assuming you have Julia ≥ 1.0:

* `add https://github.com/tlienart/JuDoc.jl`

```julia
julia> using JuDoc

julia> newsite("MyNewSite")
✔ Website folder generated at MyNewSite (now the current directory).
→ Use `serve()` to render the website and see it in your browser.

julia> serve()
→ Initial full pass... [done 2.2s]
→ Starting the server
✔ LiveServer listening on http://localhost:8000/ ...
  (use CTRL+C to shut down)
```

You can now modify the files in `MyNewSite/src` and see the changes being live-rendered in your browser.

### Features

**Supported**
* allows LaTeX-like definition of commands (via `\newcommand{..}[.]{..}`)
* allows easy inclusion of user-defined div-blocks via `@@divname ... @@` and raw-html via `~~~ ... ~~~`
* maths rendered via [KaTeX](https://katex.org/), code via [highlight.js](highlightjs.org) both can be pre-rendered (see further below)
* seamless offline editing
* within-page hyper-references for equations and citations
* simple html templating
* fast rendering (~5ms per page on warm session)
* live preview (via [LiveServer.jl](https://github.com/asprionj/LiveServer.jl))
* optimisation step for extra-light and fast website
  * pre-rendered KaTeX (requires `node`)
  * pre-rendered code highlighting (requires `node` and `highlight.js`)
  * minified output (via [`css-html-js-minify`](https://github.com/juancarlospaco/css-html-js-minify), requires `python3`)
* an all-in-one "publish" step to compile, optimise and push your website

**Coming**
* more CSS  themes (a few are available, the aim is to get ±6 good ones as per [#112](https://github.com/tlienart/JuDoc.jl/issues/112), _suggestion/contribution for other ones are welcome_)
* customisable bibliography styles
* docs

#### Templates

The templates are meant to get you started with something that looks ok and is reasonably easy to customise.

```julia
using JuDoc
newsite("site-name", template="template-name")
serve()
```

where the supported templates are currently:

| Name          | Adapted from  | Comment  |
| ------------- | -------------| -----    |
| `"basic"`     | N/A ([example](https://tlienart.github.io/)) | minimal cruft, no extra JS |
| `"hypertext"` | Grav "Hypertext" ([example](http://hypertext.artofthesmart.com/)) | minimal cruft, no extra JS |
| `"pure-sm"`   | Pure "Side-Menu" ([example](https://purecss.io/layouts/side-menu/)) | small JS for the side menu  |
| `"vela"`      | Grav "Vela" ([example](https://demo.matthiasdanzinger.eu/vela/)) | JQuery + some JS for the side menu |
| `"tufte"`      | Tufte CSS ([example (†)](https://edwardtufte.github.io/tufte-css/)) | extra font + stylesheet, no extra JS |

(†) the side notes are not (yet) implemented.

If you would like to contribute a template, please refer to the [JuDocTemplates.jl](https://github.com/tlienart/JuDocTemplates.jl) repository.

## Why

There are a lot of SSGs out there; some pretty big and established ones like [Hugo](https://gohugo.io/), [Pelican](https://blog.getpelican.com/) or [Jekyll](https://github.com/jekyll/jekyll).

In the past, I tried [Jemdoc](http://jemdoc.jaboc.net/) which I thought was nice particularly because of it simplicity.
However it is not very fast, does not allow live preview, and does not work with KaTeX (at least natively).

I also tried some of the other SSGs: Hugo, Jekyll, [Hakyll](https://jaspervdj.be/hakyll/) and [Gutenberg](https://github.com/Keats/gutenberg) but while these projects are awesome, I never felt really comfortable using them for technical notes and was looking for something that would hopefully feel quite close to LaTeX while being quite simple.

The list of goals was then to build something

* simple like Jemdoc,
* that can do live-preview with near-instantaneous rendering of modifications,
* that generates efficient webpages with as little cruft as possible,
* that allows latex-like commands,
* in Julia.

JuDoc is an attempt at meeting these criterion, help to make it better is always welcome!

## Installation

### The engine

To install JuDoc, you need [Julia](https://julialang.org/) (1.0 or above) and JuDoc (which is currently unregistered):

```julia
] # enter package mode
pkg> add https://github.com/tlienart/JuDoc.jl
```

### Pre-rendering

In order to be able to pre-render katex and highlighted code blocks (which reduces the amount of Javascript that needs to run on your webpages making your website faster), you need to have `node` available on your system.

You can test if you have it by doing

```julia
julia> run(`node -v`)
v11.14.0
Process(`node -v`, ProcessExited(0))
```

If the above command errors, you need to [install node](https://nodejs.org/en/).

#### Highlight

To pre-render things with `highlight.js`, you will need to have the `highlight.js` library on your system which you can install with `npm` (installed with node):

```
npm install highlight.js
```

(you may have to add a `sudo` in front of this).

You can test your setup with

```julia
julia> success(`node -e "const hljs = require('highlight.js')"`)
true
```

### Minifying

The files generated by JuDoc are pretty simple and thus pretty light already but they can still be compressed a bit more.
For this we use the simple [`css-html-js-minify`](https://github.com/juancarlospaco/css-html-js-minify).

If you don't already have it, JuDoc will try to install it for you via `pip3`; if it doesn't manage to install it, a warning will be raised when trying to minify the website (during `optimize`).
In that case, make sure that `python3` and `pip3` are available on your system and, in Julia, do

```julia
julia> run(`pip3 install css_html_js_minify`)
Collecting css_html_js_minify
  Using cached (...)
Installing collected packages: css-html-js-minify
Successfully installed css-html-js-minify-2.5.5
Process(`pip3 install css_html_js_minify`, ProcessExited(0))
```

If the above command fails, check that `pip3` is available on your system and can be found by Julia and check that your connection is working.

## Contributing

Contributions and comments are welcome; some notes on how you could contribute are gathered [there](https://github.com/tlienart/JuDoc.jl/blob/master/CONTRIBUTING.md).

## Licenses

**Core**:

* JuDoc, JuDocTemplates and LiveServer are all MIT licensed

**External**:

* KaTeX is [MIT licensed](https://github.com/KaTeX/KaTeX/blob/master/LICENSE)
* Node's is [permissively licensed](https://github.com/nodejs/node/blob/master/LICENSE)
* css-html-js-minify is [LGPL licensed](https://github.com/juancarlospaco/css-html-js-minify/blob/master/LICENCE.lgpl.txt)
* highlight.js is [BSD licensed](https://github.com/highlightjs/highlight.js/blob/master/LICENSE)
