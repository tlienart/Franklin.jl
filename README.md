# ONGOING

[![Build Status](https://travis-ci.org/tlienart/JuDoc.jl.svg?branch=master)](https://travis-ci.org/tlienart/JuDoc.jl)

[![codecov.io](http://codecov.io/github/tlienart/JuDoc.jl/coverage.svg?branch=master)](http://codecov.io/github/tlienart/JuDoc.jl?branch=master)


* check that everything "works"
    * fix bug with list element starting with some maths
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
