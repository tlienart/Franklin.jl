# JuDoc

[![Build Status](https://travis-ci.org/tlienart/JuDoc.jl.svg?branch=master)](https://travis-ci.org/tlienart/JuDoc.jl)

[![codecov.io](http://codecov.io/github/tlienart/JuDoc.jl/coverage.svg?branch=master)](http://codecov.io/github/tlienart/JuDoc.jl?branch=master)

Only for `0.6`, a few adaptations needed when going for `0.7` (changes for example for `replace`), will migrate to `0.7` when Juno deals with it (i.e. not yet).

## TODO / Notes

### Priority

#### Tests

in `find_replace_md.jl`
* [x] `extract_page_defs`

in `find_replace_html.jl`
* [x] `dpat`
* [x] `process_math_blocks`
* [x] `process_braces_blocks`
* [x] `split_params`
* [x] `braces_fill`
* [x] `braces_insert_if`

### Must do

* * [ ] (medium) list operations in order to make sure things never clash. For example if there happens to be a `{{}}` in a math environment, make sure the maths is extracted first.
* [ ] (medium) allow for hyper-ref using something like `{{}}` (final pass)
	* need to understand anchors and have one anchor at each equation.
		* need a `<a name="some_name">` (anchor)
		* need a `Click <a href="#some_name">here</a> to jump`
	* should be easy to have an equation counter for each doc and just increment that then find `{{eqref name}}`
* [ ] (medium) allow putting raw html maybe something like `{{ raw_html ... }}` note that this should not be parsed so it should probably be treated in much the same way as a math block.
* [ ] (low) allow for CSS variables to be defined as well.
* [ ] (low) think about performance of all these find and replace operations
  * maybe just benchmark the whole thing and the different elements
  * for replacements of the HUGO form `{{ }}` maybe better to catch all of those and deal with them in one shot (gradually forming the new string) instead of going over the text multiple times...
* [ ] (medium) in longer run, would want a repo that just has the conversion scripts etc, and then a website repo that just calls `using JuDoc`. This involves some reasoning around the paths.
  - have a script in the folder that sets the variables such as the PATH (also the base-doc-vars as that would make sense?)
	- ONGOING: cf `~/Desktop/tweb_judoc/` with the script within it. It should allow to just do `using JuDoc` set env then `convert_dir()`
* [ ] (medium) path thing is awkward (have to do the `using JuDoc` after having all the `const...`

### DONE

* [x] modularise head: base part that all pages should have, then KATEX should only be there if some HASMATH flag is on, same with PRISM
* [x] allow for comments in Markdown, things between <-- and -->
* [x] finish the removal of exclamation mark + deal with the renaming of folders.
* [x] go from `process_insert_if_blocks` which are always applied to html strings to a more general `process_html_blocks` to deal with more than just `{{ insert_if }}` but in fact a whole score of stuff (HUGO style)
  * [x] some of the doc vars should be assigned once and for all (e.g. author name) this could be done in a `config` file.
  * [x] resolve date
* [x] _see decision_ allow conditionals based on value. `{{ if value block }}` and just parse `block` if value is not empty or something like that. (e.g.: if don't want date on a page)
  - it's already possible to fill in void in some stuff (and use that as default).
  - nesting could be an issue (but who cares...)
  - DECISION: no need for that now, can just remove the offending part in the template directly, easier.
* [x] (medium) there's an `{{ insert_if ... }}` there should be an `{{ insert }}`
  - DECISION: there's now a `{{ fill ... }}`
* [x] (medium) have a way to add date of last major modification (add a variable for this)
  - DECISION: there's now something to fill a date via `@def date`
* [x] (low) sort out naming of folders `web_html`, `web_md`, `web_parts` is actually all a bit shit, really there should be an input folder and an output folder or something.
	* the `web_md` folder actually also contains the `index.html`
	* the `web_parts` ends up in `web_md` so maybe it's just easier to just put everything there but then the level of `css` and `cvx_opti` is the same which is a bit odd. Maybe can just also use `_css` just as for the output.
* [x] remove possibility to modify `web_html` (should be considered immutable)

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

* `{{ insert_if}}` goes for html, html extension is added.
* `<!-- comment -->` in markdown is a comment (no output to html)

## Design

### nice layouts

* https://retractionwatch.com/
