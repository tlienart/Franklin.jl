<div align="center">
  <a href="https://franklinjl.org">
    <img src="https://franklinjl.org/assets/infra/logoF2.svg" alt="Franklin" width="150">
  </a>
</div>

<h2 align="center">Franklin: a Static Site Generator in Julia.
<p align="center">
  <img src="https://img.shields.io/badge/lifecycle-maturing-blue.svg"
       alt="Lifecycle">
  <a href="https://travis-ci.org/tlienart/Franklin.jl">
    <img src="https://travis-ci.org/tlienart/Franklin.jl.svg?branch=master"
         alt="Build Status (Linux)">
  </a>
  <a href="https://ci.appveyor.com/project/tlienart/Franklin-jl">
    <img src="https://ci.appveyor.com/api/projects/status/github/tlienart/Franklin.jl?branch=master&svg=true"
         alt="Build Status (Windows)">
  </a>

[![AppVeyor]()]()

  <a href="http://codecov.io/github/tlienart/Franklin.jl?branch=master">
    <img src="http://codecov.io/github/tlienart/Franklin.jl/coverage.svg?branch=master"
         alt="Coverage">
  </a>
</p>
</h2>

Franklin is a simple **static site generator** (SSG) oriented towards technical blogging (code, maths, ...) and light, fast-loading pages.
The base syntax is plain markdown with a few extensions such as the ability to define and use LaTeX-like commands in or outside of maths environments and the possibility to evaluate code  blocks on the fly.

Franklin now has a channel **#franklin** on the Julia slack.

## Docs

Go to [Franklin's main website](https://franklinjl.org).

Some examples of websites using Franklin

* the main website is written in Franklin, [source](https://github.com/tlienart/franklindocs),
* [@cormullion's website](https://cormullion.github.io), the author of [Luxor.jl](https://github.com/JuliaGraphics/Luxor.jl),
* MLJ's [tutorial website](https://alan-turing-institute.github.io/MLJTutorials/) which shows how Franklin can interact nicely with [Literate.jl](https://github.com/fredrikekre/Literate.jl)
* see also [all julia blog posts](https://julialangblogmirror.netlify.com/) rendered with Franklin thanks to massive help from [@cormullion](https://github.com/cormullion); see also the [source repo](https://github.com/cormullion/julialangblog)
  * there's a project to get the official julialang website to use Franklin, [here's the POC](https://github.com/tlienart/julia-site)
* [Tom Kwong's website](https://ahsmart.com/) author of [_Hands-on Design Patterns and Best Practices with  Julia_](https://www.amazon.com/gp/product/183864881X).
* [my website](https://tlienart.github.io).

## Key features

* Use standard markdown with the possibility to use LaTeX-style commands,
* Simple way to introduce div blocks allowing easy styling on a page (e.g. "Theorem" boxes etc.),
* Can execute and show the output of Julia code blocks,
* Simple optimisation step to accelerate webpage loading speed:
  - compression of HTML and CSS of the generated pages,
  - optional pre-rendering of KaTeX and highlighted code blocks to remove javascript dependency,
* Easy HTML templating to define or adapt a given layout.

See [the docs](https://franklinjl.org) for more information and examples.

## Getting started

With Julia ≥ 1.1:

```julia
pkg> add Franklin
```

you can then get started with

```julia
julia> using Franklin

julia> newsite("MyNewSite")
✔ Website folder generated at "MyNewSite" (now the current directory).
→ Use serve() from Franklin to see the website in your browser.

julia> serve()
→ Initial full pass...
→ Starting the server...
✔ LiveServer listening on http://localhost:8000/ ...
  (use CTRL+C to shut down)
```

Modify the files in `MyNewSite/src` and see the changes being live-rendered in your browser.
Head to [the docs](https://franklinjl.org) for more information.

## Associated repositories

* [LiveServer.jl](https://github.com/asprionj/LiveServer.jl) a package coded with [Jonas Asprion](https://github.com/asprionj) to render and watch the content of a local folder in the browser.
* [FranklinTemplates.jl](https://github.com/tlienart/FranklinTemplates.jl) the repositories where Franklin themes/templates are developed.
* [franklindocs](https://franklinjl.org) the repository for Franklin's website.  

## Licenses

**Core**:

* Franklin, FranklinTemplates and LiveServer are all MIT licensed.

**External**:

* KaTeX is [MIT licensed](https://github.com/KaTeX/KaTeX/blob/master/LICENSE),
* Node's is essentially [MIT licensed](https://github.com/nodejs/node/blob/master/LICENSE),
* css-html-js-minify is [LGPL licensed](https://github.com/juancarlospaco/css-html-js-minify/blob/master/LICENCE.lgpl.txt),
* highlight.js is [BSD licensed](https://github.com/highlightjs/highlight.js/blob/master/LICENSE).
