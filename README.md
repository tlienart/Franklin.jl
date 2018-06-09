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

### Priority

* [ ] if an infra file is modified (html part) then this should trigger a re-build for all md files.

#### Tests

### Must do

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

#### Continuous time modif checking

Code below "works". Another possibility would be that, when cycling through files, checking what's the last recorded time

See [question on SO](https://stackoverflow.com/questions/50423135/monitoring-files-for-modifications)

```julia
files_and_times = Dict{String, Int}()
for (root, _, files) ∈ walkdir("web_md")
    for f ∈ files
        fpath = joinpath(root, f)
        files_and_times[fpath] = stat(fpath).mtime
    end
end
try
    while true
        for (f, t) ∈ files_and_times
            cur_t = stat(f).mtime
            if cur_t > t
                files_and_times[f] = cur_t
                println("file $f was modified")
            end
        end
        sleep(0.5)
    end
catch x
    if isa(x, InterruptException)
        println("Shutting down.")
    else
        throw(x)
    end
end
```

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

## Design

### nice layouts

* https://retractionwatch.com/
