# ONGOING

[![Build Status](https://travis-ci.org/tlienart/JuDoc.jl.svg?branch=master)](https://travis-ci.org/tlienart/JuDoc.jl)

[![codecov.io](http://codecov.io/github/tlienart/JuDoc.jl/coverage.svg?branch=master)](http://codecov.io/github/tlienart/JuDoc.jl?branch=master)


* go through github issues and remove irrelevant ones
* add doc
    * `process_file` in `manager/file_utils.jl`
* add tests
    * definition of global latex commands via config
* add future issues
    * nesting of conditions in HTML setting
    * much more testing
    * (eventually) benchmarking, though should be quite quick
    * insert content that does also need to be processed? (e.g. html). it's unclear there's a usecase for this so maybe wait until there is one...
        * one parallel situation could be to insert the content of a code file
        and display it as such. This could be done within the markdown or, in fact could leak through by writing directly in the markdown `'''julia{{ insert path_to_code.jl}}'''` which would permeate through the html conversion then bring in the jl code and display it. (could also think about inserting CSV etc.)
    * css pre-processing (variables)
* Instead of keeping the from/to in `AbstractBlock`, maybe it makes more sense to keep the `SubString`? the from to can be recovered
    * `fromto(ss)=(from=ss.offset+1, to=ss.offset+lastindex(ss))`
    * might make some stuff a bit cleaner though should not be priority
    * might help not to feed bits of string to all functions

**NOTED**
* convert_md could take a note saying that it can't contain newcommands and so `has_lxdefs=false`
* use named argument for `inmath` for readability of the code
* confusion between `head`, `head_idx` used to mean similar things (see e.g. `find_tokens`)


* merge the merge functions (they now all use the same abstract type)


### Sandbox space: math environment

To start, consider something like

```
$\sin^2(x) + \cos^2(x) \in \R$
```

* inner = substring "`\sin^2(x) + \cos^2(x) \in \R`"
* apply `find_md_lxcoms`
* reconstruct a partial gradually

later

```
\eqa{\sin^2(x)+\mycom{a}{b} = 1}
```

this one should be dealt with by a secondary call to convert_md then processing
so should be the same as tackling

```
\begin{eqnarray}\sin^2(x)+\mycom{a}{b} = 1\end{eqnarray}
```


**Problem AUG27**: at the moment trying to find lxcoms before knowing where the math
blocks are, therefore also picking in math environment. therefore the retrieve_lxdefref might actually error instead of checking whether in math environment first. This is annoying. Maybe one way out is to also deactivate tokens that are in math environments and re-get them later when the math block is being processed.
Maybe one work around is to just retrieve the xblocks before and make sure that the inside of the xblock is neutralized. For this need to investigate
`markdown/find_md_xblocks` around lines 70-80

--> this means a re-tokenization is needed in math env. Potentially wasteful.
Since text in math blocks are very small this is probably a small cost.
Could be improved by keeping a list of active token indices instead of killing
"inactive" tokens, that way could re-use the tokens. Maybe something for the future, for now might be sufficient like this.


# JuDoc

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
