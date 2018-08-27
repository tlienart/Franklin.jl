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
* Consider using references to newcommands instead of attaching a copy of the newcommand to every command?
* Use `isnothing` instead of `x == nothing` (no difference just for readability)

## Context project

* [x] find lxcommands with right number of braces early, mark as XBLOCK
* [x] add `:LX_COMS_*` in the xblocks.
* after get allblocks, reconstitute a partial MD plugging in stoppers at right place `##JD_INSERT##`
    * [x] rewrite an alternative get_allblocks which forms the intermediate md
    * [x] test it
    * **TODO** remove all calls to allblocks
* update `convert_md`
    * add `convert_md__plugblocks(...)`
    * `_procblock` qualify the arguments of the function
    * remove calls to `coms`, this impacts `resolve_latex` as well potentially
    need to think about this...
    * cleanup functions that are not used / have been replaced. Potential functions
        * `convert_md__procblock`
        * `resolve_latex`
        * resolve doc of `insert_proc_xblocks` + arguments
        * [x] remove the `stripp`
        * remove in `markdown/patterns.jl` the lines on div replace
* parse the partial MD using base markdown parser, the stoppers will be at the right place
    * update `convert_md` to use `form_interm_md` and process stoppers appropriately
* tokenize the resulting partial HTML with the tokens `##JD_INSERT##` and process considering the matching `xblocks` (for each `##JD_INSERT##` there is a `xblock`)
    * read the partial HTML until the next token
    * resolve token
        * `##JD_INSERT##` --> resolve the block or resolve latex or resolve maths
        * `@@*` --> write the appropriate replacement
    * keep writing
* (after) remove redundancy of finding braces etc in `find_md_lxcoms` and also in `resolve_latex`. Maybe some parts need to be there still.

* **Fixing of resolve_latex** now with the context thing two cases appear: first one = `LX_COM_NOARG` or `LX_COM_WARGS`, second one = math env
    * first case:
        * `LX_COM_NOARG`: `>>\com<<`: need to just find the appropriate def, convert the plug using the full conversion (*result could be cached after first call*) and plug the result in.
        * `LX_COM_WARGS`: `>>\comb{a}{b}<<`: need to find the appropriate def and the braces (that we know have already been found), check the number, apply the definition, use the full conversion machinery on the definition and plug the result in.
    * second case: math env
        * inside: `\sin^2(x)+\com = 1-\cos^2(x)+\com`
    * **>> probably you need to keep resolve latex as it is. just using SubString where appropriate and maybe develop helper functions for the first two cases which would be called in when needed**


**NOTED**
* [x] maybe verify // discrepancy between `coms` (in `convert_md` after filtering for `LX_COMMAND`) and `lxtokens` in `resolve_latex`. Should just be `lxtokens`.
* convert_md could take a note saying that it can't contain newcommands and so `has_lxdefs=false`

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
