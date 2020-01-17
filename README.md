**WARNING**: this package will be renamed soon to `Franklin.jl` (see issue [#338](https://github.com/tlienart/JuDoc.jl/issues/338)); if you're new to the package maybe wait the end of January before giving it a shot as that might help avoid issues.
If you're a current user on `<= 0.4.0` the package will keep working as it does; a coming patch release `0.4.1` will add a helper message then `0.5` will effectively be the first release of Franklin.

<div align="center">
  <a href="https://tlienart.github.io/JuDocWeb/">
    <img src="https://tlienart.github.io/JuDocWeb/assets/infra/logo1.svg" alt="JuDoc" width="150">
  </a>
</div>

<h2 align="center">A Static Site Generator in Julia.
<p align="center">
  <img src="https://img.shields.io/badge/lifecycle-maturing-blue.svg"
       alt="Lifecycle">
  <a href="https://travis-ci.org/tlienart/JuDoc.jl">
    <img src="https://travis-ci.org/tlienart/JuDoc.jl.svg?branch=master"
         alt="Build Status">
  </a>
  <a href="http://codecov.io/github/tlienart/JuDoc.jl?branch=master">
    <img src="http://codecov.io/github/tlienart/JuDoc.jl/coverage.svg?branch=master"
         alt="Coverage">
  </a>
</p>
</h2>

JuDoc is a simple **static site generator** (SSG) oriented towards technical blogging (code, maths, ...) and light, fast-loading pages.
The base syntax is plain markdown with a few extensions such as the ability to define and use LaTeX-like commands in or outside of maths environments and the possibility to evaluate code  blocks on the fly.

## Docs

Go to [JuDoc's main website](https://tlienart.github.io/JuDocWeb/).

Some examples of websites using JuDoc

* the main website is written in JuDoc, [source](https://github.com/tlienart/JuDocWeb),
* [@cormullion's website](https://cormullion.github.io), the author of [Luxor.jl](https://github.com/JuliaGraphics/Luxor.jl),
* MLJ's [tutorial website](https://alan-turing-institute.github.io/MLJTutorials/) which shows how JuDoc can interact nicely with [Literate.jl](https://github.com/fredrikekre/Literate.jl)
* see also [all julia blog posts](https://julialangblogmirror.netlify.com/) rendered with JuDoc thanks to massive help from [@cormullion](https://github.com/cormullion); see also the [source repo](https://github.com/cormullion/julialangblog)
* [my website](https://tlienart.github.io).

## Key features

* Use standard markdown with the possibility to use LaTeX-style commands,
* Simple way to introduce div blocks allowing easy styling on a page (e.g. "Theorem" boxes etc.),
* Can execute and show the output of Julia code blocks,
* Simple optimisation step to accelerate webpage loading speed:
  - compression of HTML and CSS of the generated pages,
  - optional pre-rendering of KaTeX and highlighted code blocks to remove javascript dependency,
* Easy HTML templating to define or adapt a given layout.

See [the docs](https://tlienart.github.io/JuDocWeb/) for more information and examples.

## Getting started

With Julia ≥ 1.1:

```julia
pkg> add JuDoc
```

you can then get started with

```julia
julia> using JuDoc

julia> newsite("MyNewSite")
✔ Website folder generated at "MyNewSite" (now the current directory).
→ Use serve() from JuDoc to see the website in your browser.

julia> serve()
→ Initial full pass...
→ Starting the server...
✔ LiveServer listening on http://localhost:8000/ ...
  (use CTRL+C to shut down)
```

Modify the files in `MyNewSite/src` and see the changes being live-rendered in your browser.
Head to [the docs](https://tlienart.github.io/JuDocWeb/) for more information.

## Associated repositories

* [LiveServer.jl](https://github.com/asprionj/LiveServer.jl) a package coded with [Jonas Asprion](https://github.com/asprionj) to render and watch the content of a local folder in the browser.
* [JuDocTemplates.jl](https://github.com/tlienart/JuDocTemplates.jl) the repositories where JuDoc themes/templates are developed.
* [JuDocWeb](https://github.com/tlienart/JuDocWeb) the repository for JuDoc's website.

## Licenses

**Core**:

* JuDoc, JuDocTemplates and LiveServer are all MIT licensed.

**External**:

* KaTeX is [MIT licensed](https://github.com/KaTeX/KaTeX/blob/master/LICENSE),
* Node's is essentially [MIT licensed](https://github.com/nodejs/node/blob/master/LICENSE),
* css-html-js-minify is [LGPL licensed](https://github.com/juancarlospaco/css-html-js-minify/blob/master/LICENCE.lgpl.txt),
* highlight.js is [BSD licensed](https://github.com/highlightjs/highlight.js/blob/master/LICENSE).
