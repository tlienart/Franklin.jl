# JuDoc.jl - Documentation

JuDoc is a simple **static site generator** (SSG) oriented towards technical blogging (code, maths, ...) and light, fast-loading pages.
The base syntax is plain markdown with a few extensions such as the ability to define and use LaTeX-like commands in or outside of maths environments (see the [Syntax](@ref) section).

➡ For a list of the key features see [here](#About-1).

```@raw html
➡ For a demo of available templates, see <a href="https://tlienart.github.io/JuDocTemplates.jl/" target="_blank" rel="noopener noreferrer">here</a> (opens in a new tab).
```


!!! note

    This package is still young and issues should be expected, comments, questions, bug reports etc. are welcome to make it better, see also the [Contributing](@ref) section.

On this page:

* [Installation](#Installation-1)
  * [External dependencies](#External-dependencies-1)
* [Quick start](#Quick-start-1)
* [About](#About-1)
  * [Features](#Features-1)
  * [Why?](#Why?-1)
  * [Licenses](#Licenses-1)

## Installation

With Julia ≥ 1.0,

```julia-repl
pkg> add JuDoc
```

### External dependencies

JuDoc allows a post-processing step (see [`optimize`](@ref)) which pre-renders highlighted code blocks and math environments and minifies generated HTML and CSS.
This step requires a few external dependencies:

* [`node.js`](https://nodejs.org/en/) for the pre-rendering of KaTeX and code highlighting,
* [`python3`](https://www.python.org/downloads/) for the minification of the site,
* [`git`](https://git-scm.com/downloads) for automating pushing and pulling to a remote repository.

Assuming you have those, you will then need to install `highlight.js` via `npm`:

```bash
[sudo] npm install -g highlight.js
```

and the python package [`css_html_js_minify`](https://github.com/juancarlospaco/css-html-js-minify) which you can install with `pip3` (if you have python3, JuDoc will try to do this for you):

```bash
pip3 install css_html_js_minify # mac/linux
py -3 -m pip install css_html_js_minify # windows
```

If you've installed these dependencies _after_ adding JuDoc, you will need to re-build the package with

```julia-repl
pkg> build JuDoc
```

You can subsequently check whether `JuDoc` was able to find them by looking at:

```julia-repl
julia> using JuDoc
julia> JuDoc.JD_CAN_PRERENDER
true
julia> JuDoc.JD_CAN_HIGHLIGHT
true
julia> JuDoc.JD_CAN_MINIFY
true
```

!!! note

    These external dependencies are **not required** to run JuDoc, they are just recommended to benefit from some of the post-processing machinery such as [`optimize`](@ref) or [`publish`](@ref).

### Troubleshooting

If JuDoc complains that it can't find a dependency while you believe that it is installed on your computer, you may have to help JuDoc know how to call the dependency.
For this, you can specify in your `.julia/config/startup.jl`:

```julia
ENV["PYTHON3"] = "python3"
ENV["PIP3"] = "pip3"
ENV["NODE"] = "node"
```

replace the values by however python 3, node and pip are called on your computer i.e., whatever makes the following commands work:

```julia
julia> success(`python3 -V`)
true
julia> success(`pip3 -v`)
true
julia> success(`node -v`)
true
```

#### Highlight.js

If you have issues with getting highlight.js to work, you should give these a try:

* On Windows you _may_ need to add the following to your environment variables ([source](https://stackoverflow.com/a/26480275)): `NODE_PATH=%AppData%\npm\node_modules`
* You _may_ need to use the `--save` switch ([source](https://stackoverflow.com/a/30886703)): `[sudo] npm install -g --save highlight.js`

## Quick start

Change directory to an appropriate sandbox location on your computer, start Julia and:

```julia-repl
julia> using JuDoc
julia> newsite("test", template="pure-sm")
✓ Website folder generated at "test" (now the current directory).
→ Use serve() from JuDoc to see the website in your browser.

julia> serve()
→ Initial full pass...
→ Starting the server...
✓ LiveServer listening on http://localhost:8000/ ...
  (use CTRL+C to shut down)
```

This will generate a folder `test` with overall structure:

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

The key folder in which you should work is `src/`.
For instance, a good way to become familiar with JuDoc's extended markdown syntax is to head to `src/index.md` and modify its content while keeping an eye in a browser on `http://localhost:8000/index.html`.

Once you've had a feel for the basic syntax, head over to the [Workflow](@ref) section of the manual for more information on available templates, the folder structure etc.

## About

### Features

This is a partial list of JuDoc's features that you may find interesting/useful; head to the Manual part of the docs for more details.

* ([docs](man/syntax/#LaTeX-commands-1)) LaTeX-like definition of commands (via `\newcommand{..}[.]{..}`)
* ([docs](man/syntax/#Div-blocks-1)) inclusion of user-defined div-blocks via `@@divname ... @@` and raw-html via `~~~ ... ~~~`
* ([docs](man/syntax/#Maths-1)) maths rendered via [KaTeX](https://katex.org/), code via [highlight.js](https://highlightjs.org) both can be pre-rendered (see further below)
* ([docs](man/syntax/#Hyper-references-1)) hyper-references for equations and citations
* ([docs](man/templating/)) simple html templating
* fast rendering (~5ms per page on warm session)
* live preview (via [LiveServer.jl](https://github.com/asprionj/LiveServer.jl))
* ([docs](man/workflow/#Optimisation-step-1)) optimisation step to speed up wepage rendering:
  * pre-rendered KaTeX (requires `node`)
  * pre-rendered code highlighting (requires `node` and `highlight.js`)
  * minified output (via [`css-html-js-minify`](https://github.com/juancarlospaco/css-html-js-minify), requires `python3`)
* ([docs](man/workflow/#(git)-synchronisation-1)) all-in-one "publish" step to compile, optimise and push your website

There are a few features to deal with code:

* ([docs](man/syntax/#Insertions-1)) insertion of code blocks with or without live-evaluation (a bit like [Weave.jl](https://github.com/mpastell/Weave.jl)),
* ([docs](man/workflow/#Using-Literate.jl-1)) working with [Literate.jl](https://github.com/fredrikekre/Literate.jl)


### Why?

There is a multitude of [static site generators](https://www.staticgen.com/) out there so why bother with yet another one? and is this one worth your time?

I didn't start working on JuDoc hoping to "beat" mature and sophisticated generators like Hugo etc.
Rather, a few years back I was using Jacob Mattingley's [Jemdoc](http://jemdoc.jaboc.net/using.html) package in Python with Wonseok Shin's [neat extension](https://github.com/wsshin/jemdoc_mathjax) for MathJax support and decided I wanted to build something similar in Julia (whence the name) and improve on the few things I didn't like.

!!! aside

    Interestingly, there still seems to be a number of people who use Jemdoc in academia.
    For instance [Ben Recht](http://people.eecs.berkeley.edu/~brecht/), [Madeleine Udell](https://people.orie.cornell.edu/mru8/) or [Marco Cuturi](http://marcocuturi.net/index.html).
    So working on JuDoc seemed a worthwhile.


Among the things I wanted to improve over Jemdoc were:

* support live-preview with near-instant rendering of modifications,
* generate fast-loading webpages,
* support KaTeX,
* allow LaTeX-like commands including outside of maths environment,
* better control over the layout with a simple templating system.

When compared with more serious static site generators like Hugo or Jekyll, clearly JuDoc is not in the same league.
One element that may be particularly useful though are the markdown extensions which allow to construct sophisticated commands and thereby effectively define "your own markdown flavour".

If you just want formatted text and pictures, JuDoc will probably not be very useful to you.
However, if you want to write technical documents with tables, maths, recurring elements etc, then JuDoc may be helpful.

If you think JuDoc could help you but you're not sure or you seem to be blocked by a missing feature, please [open an issue](https://github.com/tlienart/JuDoc.jl/issues/new).

### Licenses

**Core**: JuDoc, JuDocTemplates and LiveServer are all MIT licensed.

**External**: these libraries are used "as-is":

* KaTeX is [MIT licensed](https://github.com/KaTeX/KaTeX/blob/master/LICENSE),
* Node's is essentially [MIT licensed](https://github.com/nodejs/node/blob/master/LICENSE),
* css-html-js-minify is [LGPL licensed](https://github.com/juancarlospaco/css-html-js-minify/blob/master/LICENCE.lgpl.txt),
* highlight.js is [BSD licensed](https://github.com/highlightjs/highlight.js/blob/master/LICENSE),
* git is [GPL licensed](https://git-scm.com/about/free-and-open-source).
