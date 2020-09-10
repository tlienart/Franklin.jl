<div align="center">
  <a href="https://franklinjl.org">
    <img src="https://franklinjl.org/assets/infra/logoF2.svg" alt="Franklin" width="100">
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
  <a href="http://codecov.io/github/tlienart/Franklin.jl?branch=master">
    <img src="http://codecov.io/github/tlienart/Franklin.jl/coverage.svg?branch=master"
         alt="Coverage">
  </a>
</p>
</h2>

Franklin is a simple **static site generator** (SSG) oriented towards technical blogging (code, maths, ...) and light, fast-loading pages.
The base syntax is plain markdown with a few extensions such as the ability to define and use LaTeX-like commands in or outside of maths environments and the possibility to evaluate code  blocks on the fly.

Franklin now has a channel/stream **#franklin** on the Julia slack, this is the best place to ask usage question.
For anything that looks suspicious, feel free to open an issue here directly.

## Docs

Go to [Franklin's main website](https://franklinjl.org).

Some examples of websites using Franklin (_if you're using Franklin with a public repo, consider adding the "franklin" tag to the repo to help others find examples, thanks!_)

* Franklin's own website is written in Franklin, [source](https://github.com/tlienart/franklindocs)
* The [Julia website](https://julialang.org), including the blog, are deployed in Franklin.
* [@cormullion's website](https://cormullion.github.io), the author of [Luxor.jl](https://github.com/JuliaGraphics/Luxor.jl),
* MLJ's [tutorial website](https://alan-turing-institute.github.io/DataScienceTutorials.jl/) which shows how Franklin can interact nicely with [Literate.jl](https://github.com/fredrikekre/Literate.jl)
* [Tom Kwong's website](https://ahsmart.com/) author of [_Hands-on Design Patterns and Best Practices with  Julia_](https://www.amazon.com/gp/product/183864881X).
* [SymbolicUtils.jl's manual](https://juliasymbolics.github.io/SymbolicUtils.jl/) using the Tufte template
* [@terasakisatoshi's website](https://terasakisatoshi.github.io/MathSeminar.jl/) using the vela template, [source](https://github.com/terasakisatoshi/MathSeminar.jl)
* [@Wikunia's blog](https://opensourc.es) using the vela template
* [@zlatanvasovic's website](https://zlatanvasovic.github.io) using Bootstrap 4.5
* [PkgPage.jl](https://tlienart.github.io/PkgPage.jl/), front-page generator based on Franklin
* [SciML.ai](https://github.com/SciML/sciml.ai), Julia's SciML Scientific Machine Learning organization website
* [My website](https://tlienart.github.io) (_by now a bit outdated... there's only so much one can do in a day_)
* [JuliaActuary](https://JuliaActuary.org), Julia's community promoting open-source actuarial science

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

With Julia ≥ 1.3:

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

You can also start from [one of the templates](https://tlienart.github.io/FranklinTemplates.jl/) by doing something like:

```julia
julia> newsite("MyNewSite", template="vela")
```

You might want to put the following command in your `.bash_profile` or `.bashrc` as a way to quickly launch the server from your terminal:

```
alias franklin=julia -O0 -e 'using Franklin; serve()'
```

### Heads up!

While Franklin broadly supports standard Markdown there are a few things that may trip you which are either due to Franklin or due to Julia's Markdown library, here are key ones you should keep in mind:

* when writing a list, the content of the list item **must** be on a single line (no line break)
* you can write comments with `<!-- comments -->` the comment markers `<!--` and `-->` **must** be separated by a character that is not a `-` to work properly so `<!--A-->` is ok but `<!---A--->` is not, best is to just systematically use a whitespace: `<!-- A -->`.
* be careful writing double braces, `{{...}}` has a *meaning* (html functions) this can cause issues in latex commands, if you have double braces in a latex command, **make sure to add whitespaces** for instance write `\dfrac{1}{ {101}_{2} }` instead of `\dfrac{1}{{101}_{2}}`. In general use whitespaces liberally to help the parser in math and latex commands.
* (as of `v0.7`) code blocks should be delimited with backticks `` ` `` you *can* also use indented blocks to delimit code blocks but you now have to **opt in** explicitly on pages that would use them by using `@def indented_code = true`, if you want to use that everywhere, write that in the `config.md`. Note that indented blocks are **ambiguous** with some of the other things that Franklin provides (div blocks, latex commands) and so if you use them, you are responsible for avoiding ambiguities (effectively that means _not using indentation for anything else than code_)



## Associated repositories

* [FranklinFAQ](https://github.com/tlienart/FranklinFAQ) a repo with basic demos following questions "_how do you do X with Franklin_"
* [LiveServer.jl](https://github.com/asprionj/LiveServer.jl) a package coded with [Jonas Asprion](https://github.com/asprionj) to render and watch the content of a local folder in the browser.
* [FranklinTemplates.jl](https://github.com/tlienart/FranklinTemplates.jl) the repositories where Franklin themes/templates are developed.

## Licenses

**Core**:

* Franklin, FranklinTemplates and LiveServer are all MIT licensed.

**External**:

* KaTeX is [MIT licensed](https://github.com/KaTeX/KaTeX/blob/master/LICENSE),
* Node's is essentially [MIT licensed](https://github.com/nodejs/node/blob/master/LICENSE),
* css-html-js-minify is [LGPL licensed](https://github.com/juancarlospaco/css-html-js-minify/blob/master/LICENCE.lgpl.txt),
* highlight.js is [BSD licensed](https://github.com/highlightjs/highlight.js/blob/master/LICENSE).
