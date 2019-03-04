# JuDoc

| Status | Coverage |
| :----: | :----: |
| [![Build Status](https://travis-ci.org/tlienart/JuDoc.jl.svg?branch=master)](https://travis-ci.org/tlienart/JuDoc.jl) | [![codecov.io](http://codecov.io/github/tlienart/JuDoc.jl/coverage.svg?branch=master)](http://codecov.io/github/tlienart/JuDoc.jl?branch=master) |

1. [What's this about](#about)
    1. [Features](#features)
    1. [Short example](#short-ex1)
1. [Why](#why)
1. [Installation](#installation)
    1. [The engine](#the-engine)
    1. [Rendering](#rendering)
    1. [Minifying](#minifying)
    1. [Getting started](#getting-started)
        1. [Folder structure](#folder-structure)
    1. [Running](#running)
1. [Contributing](#contributing)

## What's this about? <a id="about"></a>

JuDoc is a simple static site generator (SSG) oriented towards technical blogging (code, maths, ...) and written in Julia.
I use it to generate [my website](https://tlienart.github.io).

### Features

**Supported**
* allows LaTeX-like definition of commands (via `\newcommand{..}[.]{..}`)
* allows easy inclusion of user-defined div-blocks and raw-html
* maths rendered via [KaTeX](https://katex.org/), code via [highlight.js](highlightjs.org)
* seamless offline editing
* within-page hyper-references for equations and citations
* simple html templating
* fast rendering (~5ms per page on warm session)
* live preview (partly via [`browsersync`](https://browsersync.io/))
* minified output (via [`css-html-js-minify`](https://github.com/juancarlospaco/css-html-js-minify))

**Coming**
* customisable bibliography styles
* CSS themes (*if you want to help, let me know!*)

### Short example <a id="short-ex1"></a>

To give an idea of the syntax, the source below renders to [this page](https://tlienart.github.io/pub/misc/judoc-example1.html) (open it in a new tab/window to compare).

<!-- =========== EXAMPLE =========== -->
```markdown
<!-- These are page variables that are used to control the templating and
the rendering of the final html. For instance the title will lead to an
appropriate <title> element. -->
@def isdemo = true
@def hascode = true
@def title = "Example"

<!-- Commands can be defined just like in LaTeX, this can be very useful
in math-environments but also for other recurring elements -->
\newcommand{\R}{\mathbb R}
\newcommand{\E}{\mathbb E}
\newcommand{\scal}[1]{\left\langle #1 \right\rangle}

# JuDoc Example

You can define commands in a same way as in LaTeX, and use them in the same
way: $\E[\scal{f, g}] \in \R$.
Math is displayed with [KaTeX](https://katex.org) which is faster than MathJax
and generally renders better.
Note below the use of `\label` for hyper-referencing, this is not natively
supported by KaTeX but is handled by JuDoc.

$$ \hat f(\xi) = \int_\R \exp(-2i\pi \xi t) \,\mathrm{d}t. \label{fourier} $$

The syntax is basically an extended form of GitHub Flavored Markdown
([GFM](https://guides.github.com/features/mastering-markdown/))
allowing for some **LaTeX** as well as **div blocks**:

@@colbox-yellow
Something inside a div with div name "colbox-yellow"
@@

You can add figures, tables, links and code just as you would in GFM.
For syntax highlighting, [highlight.js](https://highlightjs.org) is used by
default.

## Why?

Extending Markdown allows to define LaTeX-style commands for things that may
appear many times in the current page (or in all your pages), for example let's
say you want to define an environment for systematically inserting images from
a specific folder within a specific div.
You could do this with:

\newcommand{\smimg}[1]{@@img-small ![](/assets/misc/smimg/!#1) @@}

\smimg{marine-iguanas-wikicommons.jpg}

It also allows things like hyper-referencing as alluded to before:

$$ \exp(i\pi) + 1 = 0 \label{a nice equation} $$

can then be referenced as such: \eqref{a nice equation} unrelated to
\eqref{fourier} which is convenient for maths notes.
```

<!-- =========== end EXAMPLE =========== -->

## Why

There are a lot of SSGs out there with some pretty big and established ones like [Hugo](https://gohugo.io/), [Pelican](https://blog.getpelican.com/) or [Jekyll](https://github.com/jekyll/jekyll).

In the past, I tried [Jemdoc](http://jemdoc.jaboc.net/) which I thought was nice particularly because of it simplicity.
However it was not very fast, did not allow live preview, and did not work with KaTeX (at least natively).

I tried some of the other SSGs: HuGo and Jekyll but also others like  [Hakyll](https://jaspervdj.be/hakyll/) and [Gutenberg](https://github.com/Keats/gutenberg) but while these projects are awesome, I never felt very comfortable using them for technical notes, something that would hopefully feel quite close to LaTeX.

So my list of desiderata was to write something

* simple like JemDoc,
* that could do live-preview with near-instantaneous rendering of modifications,
* that generated efficient webpages with as little cruft as possible,
* that allowed latex-like commands,
* in Julia.

## Installation

In short:

* `add https://github.com/tlienart/JuDoc.jl` in Julia ≥ 0.7
* `npm install -g browser-sync`
* `pip install css-html-js-minify`

Then in your site directory

```julia-repl
julia> using JuDoc
julia> serve()
Starting the engine (give it 1-2s)...
Now live-serving at http://localhost:8000/... ✅
Watching input folder, press CTRL+C to stop...
```

more details below.

### The engine

To install JuDoc, you need [Julia](https://julialang.org/) (0.7 or above) and JuDoc (which is currently unregistered):

```
] # enter package mode
(v 1.0) > add https://github.com/tlienart/JuDoc.jl
```

### Rendering

To render your site locally, `JuDoc.serve()` uses [`browser-sync`](https://browsersync.io/) which allows you to directly see the modifications you make in your browser.
It is not necessary to install it i.e.: you could just run JuDoc, push the pages on GitHub and see how they get rendered there but it's easier to see how your website renders locally with any modifications you make being applied live.
To install [`browser-sync`](https://browsersync.io/) just run

```
npm install -g browser-sync
```

(which requires you to have [`npm`](https://www.npmjs.com/get-npm) but it's unlikely you don't.)

### Minifying

The files generated by JuDoc are pretty simple and thus pretty light already but they can still be compressed a bit more.
For this we use the simple [`css-html-js-minify`](https://github.com/juancarlospaco/css-html-js-minify) which can be installed via `pip`:

```
pip install css-html-js-minify
```

Again, it's not a required dependency, it is however encoded in `JuDoc.publish()` so if you use that, JuDoc will assume that you have it.

**Remark** there are more sophisticated minifiers out there however the script above is simple and has the added advantage that it doesn't clash with KaTeX which, for instance, [`html-minifier`](https://github.com/kangax/html-minifier) does as far as I can tell.

### Getting started

The easiest is probably that you just head to [the JuDocExample repo](https://github.com/tlienart/JuDocExample) and experiment from there then come back here.
The added advantage is that you would have a KaTeX release which I know works with JuDoc as more recent releases may not.

The starting point should be a folder with the following structure (the folders/files marked with a star *must* be there)

```
site
+-- assets
+-- libs (*)
|   +-- katex
|   +-- highlight
+-- src (*)
|   +-- _css (*)
|   +-- _html_parts (*)
|   +-- pages (*)
|   |   +-- folder1 ...
|   |   +-- folder2 ...
|	|	+-- ...
|   +-- config.md
|   +-- index.md
```

The folders can be described as follows:

* `assets`: essentially contains files like images.
* `libs`: contains files necessary to run libraries such as [KaTeX](https://katex.org) and [highlight.js](https://highlightjs.org/).
* `src`: this is the folder where you work
    * `src/_css`: is where you should modify your CSS files
    * `src/_html_parts`: is where basic html building blocks are defined (head, foot etc) which are used in assembling the final pages
    * `src/pages/*`: is where you should put your notes in `.md` files
    * `src/config.md`: is a global configuration file where you can store variables such as the author name or latex commands you want to be able to use throughout
    * `src/index.md`: is the file corresponding to the landing page

Note that `src/pages/*` can contain plain html files which will be available to your website untouched, in a similar way, you can write the landing page directly in html and just have `src/index.html` instead of `src/index.md` if you prefer.

After running JuDoc, a few extra folders will appear (marked with a dagger)

```
site
+-- assets
+-- css (†)
+-- libs
+-- pub (†)
|   +-- folder1 ...
|   +-- folder2 ...
+-- src
+-- index.html (†)
```

* `css/`: contains the css that your website will use, it's effectively copied (and possibly minified) from `src/_css/*`
* `pub/*`: contains all the (possibly minified) html pages that have been generated from your `.md` notes
* `index.html`: is the generated landing page from `index.md`

### Running

The first time you will apply `JuDoc.serve()` it will take 1 or 2 seconds to start (this is standard in Julia, the package and the functions need to be compiled), once it's running, modifications will be applied instantaneously.

Also, if you stop the engine using `CTRL+C` and re-start it with `JuDoc.serve()` the initial delay will not be present anymore.

For this reason, it is recommended to run `JuDoc.serve()` from within a Julia session as opposed, for instance, to running it from your bash:

```
julia -e "using JuDoc; serve()"
```

This would work as well of course but if, for some reason, you wish to stop the engine then start it again, you will each time need to wait for that initial short delay.

## Contributing

Initially I wrote this project because I thought it was interesting for me.
I'm now thinking it may be interesting to others too and as a result, contributions to make this project better would be very welcome.

Some notes on how to contribute are gathered [there](https://github.com/tlienart/JuDoc.jl/blob/master/CONTRIBUTING.md).
