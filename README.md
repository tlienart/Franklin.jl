# JuDoc

| [MacOS/Linux] | Windows | Coverage | Documentation |
| :-----------: | :-----: | :------: | :-----------: |
| [![Build Status](https://travis-ci.org/tlienart/JuDoc.jl.svg?branch=master)](https://travis-ci.org/tlienart/JuDoc.jl) | [![AppVeyor](https://ci.appveyor.com/api/projects/status/github/tlienart/JuDoc.jl?branch=master&svg=true)](https://ci.appveyor.com/project/tlienart/JuDoc-jl) | [![codecov.io](http://codecov.io/github/tlienart/JuDoc.jl/coverage.svg?branch=master)](http://codecov.io/github/tlienart/JuDoc.jl?branch=master) | [![](https://img.shields.io/badge/docs-stable-blue.svg)](https://tlienart.github.io/JuDoc.jl/stable) [![](https://img.shields.io/badge/docs-dev-blue.svg)](https://tlienart.github.io/JuDoc.jl/dev) |

JuDoc is a simple **static site generator** (SSG) oriented towards technical blogging (code, maths, ...) and light, fast-loading pages.
The base syntax is plain markdown with a few extensions such as the ability to define and use LaTeX-like commands in or outside of maths environments.

See [the docs](https://tlienart.github.io/JuDoc.jl/stable) for more information.

A couple of websites using JuDoc:
* [@cormullion's website](https://cormullion.github.io), the author of [Luxor.jl](https://github.com/JuliaGraphics/Luxor.jl),
* [my website](https://tlienart.github.io).
* see also how [some julia blog posts](https://tlienart.github.io/julia-blog-migration/) render with JuDoc (note: _focus on the rendering, not the layout/CSS_) see also [the source repo](https://github.com/tlienart/julia-blog-migration).

### Key features

* Use standard markdown with the possibility to use LaTeX-style commands,
* Simple way to introduce div blocks allowing easy styling on a page (e.g. "Theorem" boxes etc.),
* Can execute and show the output of Julia code blocks,
* Simple optimization step to accelerate webpage loading speed:
  - compression of HTML and CSS of the generated pages,
  - optional pre-rendering of KaTeX and highlighted code blocks to remove javascript dependency,
* Easy HTML templating to define or adapt a given layout.

See [the docs](https://tlienart.github.io/JuDoc.jl/stable) for more information and examples.

### Quick demo

With Julia ≥ 1.0:

```julia
pkg> add JuDoc
```

and then you can get started with

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

You can now modify the files in `MyNewSite/src` and see the changes being live-rendered in your browser.
Head to [the docs](https://tlienart.github.io/JuDoc.jl/stable) for more information.

## Associated repositories

* [LiveServer.jl](https://github.com/asprionj/LiveServer.jl) a package coded with [Jonas Asprion](https://github.com/asprionj) to render and watch the content of a local folder in the browser.
* [JuDocTemplates.jl](https://github.com/tlienart/JuDocTemplates.jl) the repositories where JuDoc themes/templates are developed.

## Licenses

**Core**:

* JuDoc, JuDocTemplates and LiveServer are all MIT licensed

**External**:

* KaTeX is [MIT licensed](https://github.com/KaTeX/KaTeX/blob/master/LICENSE)
* Node's is essentially [MIT licensed](https://github.com/nodejs/node/blob/master/LICENSE)
* css-html-js-minify is [LGPL licensed](https://github.com/juancarlospaco/css-html-js-minify/blob/master/LICENCE.lgpl.txt)
* highlight.js is [BSD licensed](https://github.com/highlightjs/highlight.js/blob/master/LICENSE)
