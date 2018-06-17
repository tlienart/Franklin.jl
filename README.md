# JuDoc

[![Build Status](https://travis-ci.org/tlienart/JuDoc.jl.svg?branch=master)](https://travis-ci.org/tlienart/JuDoc.jl)

[![codecov.io](http://codecov.io/github/tlienart/JuDoc.jl/coverage.svg?branch=master)](http://codecov.io/github/tlienart/JuDoc.jl?branch=master)

Only for `0.6`, a few adaptations needed when going for `0.7` (changes for example for `replace`), will migrate to `0.7` when Juno deals with it (i.e. not yet).

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

## TODO / Notes

### Bugs

* [x] does not seem to be tracking changes on `index.md`
* [x] does not seem to be tracking new files
* [x] does not seem to deal with maths within a DIV. check order.
* [ ] deal with image insertion
* [ ] handle numbering of equations (nonumber, labels...)
* [ ] allow for simple latex definitions
* [ ] extract default title from first h1 element

### Priority

* [ ] if an infra file is modified (html part) then this should trigger a re-build for all md files.

#### Tests

### Must do

**IF**
* [ ] (low) should allow either a variable key referencing a bool or fall back and try to interpret as a bool? Ideally would want to be able to do something like

```
[[ if !date==nothing {{fill date}} ]]
```

the difficulty being that we'd now need to parse `!date==nothing`, work out where the variable is, look it up the dictionary then interpret the condition... Maybe:

```
[[ if var ... ]] # amounts to if true(var, identity)
[[ if ==(var, expr) ... ]] # also eq(var, expr)
[[ if !=(var, expr) ... ]] # also neq(var, expr)
[[ if ∈(var, expr) ... ]] # also in(var, expr)
[[ if ∉(var, expr) ... ]] # also notin(var, expr)
[[ if true(var, fun) ... ]]
[[ if false(var, fun) ... ]]
```

difficulty is capturing all of those especially if `expr` can be arbitrarily complex. This may require actually building a stack for parens matching etc.

* [ ] (low) allow for an **else** statement? maybe `[[ if v ... ][ else ... ]]` can do elseif as well same way I guess.

**DATES**
* [ ] (low) dates management, `Dates.today()` is no good, every time the file is recompiled (often). Or should just not re-interpret if there's no diff. The latter would require keeping track of the files + time of last modification in a hidden file that is gitignored.
* [ ] (low) dates (and else), if empty, nothing should appear.
* [ ] (low) dates, all dates should have the same format (atm, it could be different).

```julia
Dates.format(now(), "U dd, yyyy")
Dates.format(Date(2018, 5, 15), "dd U yyyy")
```

See also [formats](https://en.wikibooks.org/wiki/Introducing_Julia/Working_with_dates_and_times).

**HTML**
* [ ] (low) remove all comments from HTML
* [ ] (low) div block nesting would not be handled well (would need recursive call of `div_blocks`, might be reasonably easy to do though)
* [ ] (low) raw html

**DRAFT**
* [ ] (low) allow for **draft** files (should be visible locally but not globally or something)
* [ ] (medium) dealing with CSS processing
  - `_css` folder now needs to be tracked too (in any case that's a good idea)
  - `_css` files now need to be processed like html
  - changes to `prepare_output_dir` ?
  - changes to `convert_dir`
* [ ] (medium) it may be a good idea to not systematically `rm` the output dir. In particular this is true for the assets. Assets should just be diff-ed. Some thoughts on stale files (files that have changed names). Basis should always be that `web_output` is a compiled version of `input` and therefore anything that doesn't match something in `input` should be `rm`-d.
* [ ] (medium) list operations in order to make sure things never clash. For example if there happens to be a `{{}}` in a math environment, make sure the maths is extracted first.
* [ ] (low) start some form of "clever" doc so that you keep track of stuff.
* [ ] (medium) allow for hyper-ref using something like `{{}}` (final pass)
	* need to understand anchors and have one anchor at each equation.
		* need a `<a name="some_name">` (anchor)
		* need a `Click <a href="#some_name">here</a> to jump`
	* should be easy to have an equation counter for each doc and just increment that then find `{{eqref name}}`
* [ ] (medium) allow putting raw html maybe something like `{{ raw_html ... }}` note that this should not be parsed so it should probably be treated in much the same way as a math block.
* [ ] (low) allow for CSS variables to be defined as well. Possibly use the same `{{fill}}` syntax.
* [ ] (low) think about performance of all these find and replace operations
  * maybe just benchmark the whole thing and the different elements
* [ ] (low) need to have the templates stored somewhere, possibly a side repo. this can be done when the site is a bit established and the CSS/HTML has converged a bit.

**Counters**
* [ ] (low) counters for sections + references (similar to hyperref)

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

### Draft notes

* not recommended to change output dir or input dir (i.e. recommended to leave `web_md` and `web_html`). If you must, make sure to update your `.gitignore`.
* if want to update CSS, need to update in `web_html` (or name of output dir) and it will be directly apparent. Don't touch the template CSS in `templates/`

## Pre-docs

### Local simple web server installation (EXTERNAL)

```bash
npm install -g local-web-server
```

actually [this](https://medium.com/@svinkle/start-a-local-live-reload-web-server-with-one-command-72f99bc6e855) is even better with live reload.
It looks like it may be possible to do this with a combination of `WebSockets.jl` and `HTTP.jl` but haven't figured out how yet. Package `Pages.jl` may offer some (out of date) help.

### Running

```
cd web_html
ws
# -> go to localhost:8000
```

### Libraries and paths

* `PATH_INPUT_CSS` for the css
* `PATH_INPUT_HTML` for the HTML parts (head, foot, ...)
* `PATH_INPUT_LIBS` for js libs (base = `prism` for highlighting and `katex` for maths)

### Variables

Assume what's given will not crash everything (no sandboxing)

* `hasmath` : will include the KATEX header and footer
* `hascode` : will include the PRISM header
* `isnotes` : will include the `content.css` (recommended)

### special stuff

* `{{ insert_if ...}}` goes for html, html extension is added.
* `<!-- comment -->` in markdown is a comment (no output to html)
* `{{ fill ...}}` fill with a doc variable or page var
* `[[if ...]]` use block if some bool
* no input file should be named `config.md` apart from the one and only file containing the global configuration for the full website.

## Jd vars

* `jd_ctime` file creation (for md file)
* `jd_mtime` last modif (for md file)

## Design

### nice layouts

* https://retractionwatch.com/
* http://arrgh.tim-smith.us/

### Variables

JD_GLOB_VARS    Def. Val        Note
---             ---             ---
author          "THE AUTHOR"      (String, Void)
date_format     "U dd, yyyy"    Jan 01, 2011 (String,)


JD_LOC_VARS     Def. Val        Note
---             ---             ---
hasmath         true            (Bool,)
hascode         false           (Bool,)
isnotes (†)     true            (Bool,)
title           "THE TITLE"     (String,)
date            Date()          (String, Date, Void)
jd_ctime ⭒      Date()          (Date,)
jd_mtime ⭒      Date()          (Date,)
