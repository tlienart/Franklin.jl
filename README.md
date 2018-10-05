# ONGOING

| Linux/Mac 0.7+nightlies | Coverage |
| ---- | ---- |
| [![Build Status](https://travis-ci.org/tlienart/JuDoc.jl.svg?branch=master)](https://travis-ci.org/tlienart/JuDoc.jl) | [![codecov.io](http://codecov.io/github/tlienart/JuDoc.jl/coverage.svg?branch=master)](http://codecov.io/github/tlienart/JuDoc.jl?branch=master) |

# JuDoc

## What's this about?

JuDoc is a simple static site generator oriented towards technical blogging and written in Julia.

This:
```md
@def title = "Example"

\newcommand{\R}{\mathbb R}
\newcommand{\E}{\mathbb E}
\newcommand{\scal}[1]{\langle #1 \rangle}

You can define commands in a same way as LaTeX.
And use them in the same way: $\E[\scal{f, g}] \in \R$.
Maths display is done with [KaTeX](https://katex.org).

The syntax is basically an extended form of [gfm](https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet) allowing for some LaTeX as well as div blocks:

@@box
Something inside a div with div name "box"
@@

You can add figures, tables, links and code just as you would in gfm.

Extending Markdown allows to define macros for things that may appear many times in the current page (or in all your pages), for example let's say you want to define an environment for systematically inserting images from a specific folder within a specific div.

\newcommand{\smimg}[1]{@@smimg ![](/assets/smimg/!#1) @@}

\smimg{myimg.png}

It also allows things like referencing (which is not natively supported by KaTeX for instance):

$$ \exp(i\pi) + 1 = 0 \label{a nice equation} $$

can then be referenced as such: \eqref{a nice equation} which is convenient for maths notes.
```

Renders to


## Getting started

must start with something like (the folders/files marked with a star *must* be there)

```
site
+-- libs (*)
|   +-- katex
|   +-- prism
+-- src (*)
|   +-- _css (*)
|   +-- _html_parts (*)
|   +-- pages (*)
|   |   +-- folder1 ...
|   |   +-- folder2 ...
|   +-- config.md
|   +-- index.md
+-- run_jdoc.jl (*)
```

where `run_jdoc.jl` is something like

```julia
using JuDoc
FOLDER_PATH = @__DIR__
judoc(single_pass=false)
```

this leads to (files/folders marked with a † are generated)

```
site
+-- css (†)
+-- libs
+-- pub (†)
|   +-- folder1 ...
|   +-- folder2 ...
+-- src
+-- index.html (†)
+-- run_jdoc.jl
```

### Todo

* Benchmark

**Exit**
* [ ] (low) in running script need

```julia
ccall(:jl_exit_on_sigint, Void, (Cint,), 0)
```

otherwise segfault on CTRL+C (outside of REPL). Should encourage doing stuff in the REPL (not like Hugo). For productionised version can have a small shell script or something that launches Julia with appropriate first few lines or something.

### Thoughts

* user needs to add their own `prism.css` to match the languages they want to highlight (current one is bash, julia, python, R, yaml)
* minify katex eventually. --> maybe production mode option, just use python `css-html-js-minify web_html/` which is great. Need to make sure all lib paths are done with `.min` though!
	* could have a final pass with some `{{}}` stuff. Probably also useful for things like equation numbers and hyper-references.

### Local simple web server installation (EXTERNAL)

```bash
npm install -g local-web-server
```

actually [this](https://medium.com/@svinkle/start-a-local-live-reload-web-server-with-one-command-72f99bc6e855) is even better with live reload.
It looks like it may be possible to do this with a combination of `WebSockets.jl` and `HTTP.jl` but haven't figured out how yet. Package `Pages.jl` may offer some (out of date) help.


## Design

### nice layouts

* https://retractionwatch.com/
* http://arrgh.tim-smith.us/
* https://amol9.github.io/2017/02/21/Making-Asynchronous-Http-Requests-With-Julia/ clean menu hidden always unless clicked. same behaviour for mobile.
