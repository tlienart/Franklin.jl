# Workflow

In this workflow it is assumed that you will eventually host your website on GitHub or GitLab but it shouldn't be hard to adapt to your particular case.

**Contents**:

* [Local editing](#Local-editing-1)
  * [Structure](#Structure-1)
* [Libraries](#Libraries-1)
  * [Highlight](#Highlight-1)
* [Hosting the website](#Hosting-the-website-1)
* [Optimisation step](#Optimisation-step-1)
* [(git) synchronisation](#(git)-synchronisation-1)
  * [Merge conflicts](#Merge-conflicts-1)
* [0000000Literate programming (and blogging) with Literate.jl](#Literate-programming-(and-blogging)-with-Literate.jl-1)

## Local editing

To get started, the easiest is to use the [`newsite`](@ref) function to generate a website folder which you can then modify to your heart's content.
The command takes one mandatory argument: the name of the folder, and you can specify a template with `template=...`:

```julia-repl
julia> newsite("Test"; template="pure-sm")
✓ Website folder generated at Test (now the current directory).
→ Use `serve()` from `JuDoc` to see the website in your browser.
```

where the supported templates are currently:

| Name          | Adapted from  | Comment  |
| :------------- | :-------------| :-----    |
| `"basic"`     | N/A ([example](https://tlienart.github.io/)) | minimal cruft, no extra JS |
| `"hypertext"` | Grav "Hypertext" ([example](http://hypertext.artofthesmart.com/)) | minimal cruft, no extra JS |
| `"pure-sm"`   | Pure "Side-Menu" ([example](https://purecss.io/layouts/side-menu/)) | small JS for the side menu  |
| `"vela"`      | Grav "Vela" ([example](https://demo.matthiasdanzinger.eu/vela/)) | JQuery + some JS for the side menu |
| `"tufte"`      | Tufte CSS ([example](https://edwardtufte.github.io/tufte-css/)) | extra font + stylesheet, no extra JS |

Once you have done that, you can serve your website once in the folder doing

```julia-repl
julia> serve()
✓ LiveServer listening on http://localhost:8000/ ...
  (use CTRL+C to shut down)
```

and navigate in a browser to the corresponding address to see the website being rendered.

!!! note

    If you're using the Atom editor, you may like to use the _Atom browser_ extension which allows you to have a browser in an Atom pane.

### Structure

The [`newsite`](@ref) command above generates folders and examples files following the appropriate structure, so the easiest is to start with that and modify in place.

```
.
├── assets/
├── libs/
└── src/
```

Once you run [`serve`](@ref) the first time, two additional folders are generated (`css/` and `pub/`) along with the landing page `index.html`.

Among these folders,

* the **main folder** is `src/` and its subfolders, this is effectively where the source for your site is,
* you should _ignore_ `css/` and `pub/` these are _generated_ and any changes you'd do there will be silently over-written whenever you modify files in `src/`; the same comment holds for `index.html`,
* the folders `assets/` and `libs/` contain _auxiliary items_ that are useful for your site: `assets/` would contain code snippets, images etc. while `libs/` would contain javascript libraries that you may need (KaTeX and highlight are in there by default).

In the `src/` folder, the structure is:

```
.
├── _css
│   ├── judoc.css
│   └── ...
├── _html_parts
│   ├── foot.html
│   ├── head.html
│   └── ...
├── config.md
├── index.md
└── pages
    ├── page1.md
    └── ...
```

**Pages**

The `index.md` will generate the site's landing page.
The `pages/page1.md` would correspond to pages on your website (you can have whatever subfolder structure you want in there, and will just have to adapt internal links appropriately).
See also the [Syntax](@ref).

!!! note

    At any point you can write pages in HTML from scratch if you want to go beyond what JuDoc can offer; these pages will just be copied as they are.
    So for instance you may prefer to write an `index.html` file instead of using the `index.md` to generate it.
    You would still put it at the exact same place though (`src/index.html`) and let JuDoc copy the files at the appropriate place.

**HTML parts**

The files in `_html_parts/` are the building blocks that will go around the (processed) content contained in the `*.md` pages.
So the `head.html` will be inserted before, the `foot.html` after etc.
Adjusting these will help you make sure the site has the exact layout you want.
The layout can also depend on the page you're on if it uses `{{ispage path/to/page}} ... {{end}}`  (see [`Templating`](@ref)).

**CSS**

Unsurprisingly, the style sheets in `_css/` will help you tune the way your site looks.
The `judoc.css` is the stylesheet that corresponds more specifically to the styling of the `.jd-content` div and all that goes in it, it is usually the first style-sheet that should be loaded.
The simplest way to adjust the style easily would be to define your own stylesheet `_css/adjustments.css` and it be the last stylesheet loaded in `_html_parts/head.html` so that you can easily overwrite whatever properties you don't like and define your own.
You could also have specific stylesheet that would only be loaded on specific pages using `{{ispages ...}}` (see [Templating](@ref)).

!!! note

    It wouldn't be hard for JuDoc to use page variables in the CSS stylesheet too. You could then do things like
    ```judoc
    @def col1 = aliceblue
    ```
    and
    ```css
    .mydiv { color: $col1 }
    ```
    I'm not 100% sure how useful that could be though so if you would like to see this happen, please open an issue!

## Libraries

If you used the [`newsite`](@ref) function to get started, then you should have a `libs/` folder with

```
.
├── highlight/
└── katex/
```

If you require other libraries to run your website, this is where you should put them while not forgetting to load them in your `_html_parts`; for instance in `foot_highlight.html` you will find:

```html
<script src="/libs/highlight/highlight.pack.js"></script>
<script>hljs.initHighlightingOnLoad();hljs.configure({tabReplace: '    '});</script>
```

### Highlight

If you used the [`newsite`](@ref) command then the `libs/highlight/` folder contains

```
.
├── github.min.css
└── highlight.pack.js
```

Of course if you want to change either how things look or which languages are supported, you should head to [highlightjs.org](https://highlightjs.org/download/), select the languages you want in the **Custom package** section, download the bundle and copy over the relevant files to `libs/highlight/`.
By default, `bash`, `html/xml`, `python`, `julia`, `julia-repl`, `css`, `r`, `markdown`, `ini/TOML`, `ruby` and `yaml` are supported.

Just remember to refer to the appropriate style-sheet in your HTML building blocks for instance `src/_html_parts/head_highlight.html`:

```html
<link rel="stylesheet" href="/libs/highlight/github.min.css">
```

## Hosting the website

In this section, the assumption is that you will host your website on GitHub.
The procedure should be very similar with GitLab.
If you're using your own hosting, you would pretty much just need to copy/clone the content of your folder.

On GitHub/GitLab, the first step is to create a repository that would be acceptable for a personal webpage.

* Follow the guide to [do so on GitHub](https://pages.github.com/#user-site).
* Or the guide to [do so on GitLab](https://about.gitlab.com/product/pages/).

Once the repository is created, clone it on your computer, remove whatever is in it if it wasn't empty and copy over the content of the website folder (so if you had done `newsite("Test/")` then you'd copy over the content of the folder `Test` into the newly cloned folder `username.github.io/`).

Now just do the usual `git add`, `commit` and `push` and your site will be live in a matter of minutes.

## Optimisation step

The [`optimize`](@ref) function should typically be run before you push your website online.
That step can:

1. pre-render KaTeX and highlight code to HTML so that the pages don't have to load these javascript libraries,
1. minify all generated HTML and CSS.

Those steps (which you can opt out of using the appropriate keyword `prerender=false` or `minify=false`) may lead to faster loading pages.

In order to run this optimisation step, you will need some [Dependencies](#Dependencies-1) but if you don't have them, JuDoc will tell you and ignore the corresponding step.
Note also that doing a full pass of pre-rendering and minifying may take a few seconds depending on how many pages you have.

## (git) synchronisation

The [`publish`](@ref) function helps you wrap the [`optimize`](@ref) step as well as a git `add`, `commit` and `push` all in one (provided the `optimize` step didn't fail).

So, in short, your full workflow may look like

```julia
using JuDoc
# cd to the appropriate directory
cd("path/user.github.io")
# start serving
serve()
# ...
# edit things, add pages, tune layout etc.
# while keeping an eye on the browser to check
# ...
# all looks good, stop the server with CTRL+C
^C
# and now the final step to optimize and push:
publish()
```

### Merge conflicts

Since the `pub/` and `css/` and `index.html` folder are _generated_, it can sometimes cause git merge conflicts if, for instance, you have edited your website on computer A, optimised and published it and then subsequently pulled on computer B where -- say -- the content hasn't been minified yet.
This could cause messy merge conflicts that would be annoying to fix.
An easy way to reduce this risk is to simply remove the generated folders and files before pulling.

The function [`cleanpull`](@ref) does precisely that and should be used if you intend to edit your website from multiple computers.
It simply:

1. removes all generate folders/files from your current director,
1. pulls.

So in such a case, your full workflow would be:

```julia
using JuDoc
cd("path/user.github.io")
cleanpull()
serve()
# ...
publish()
```

## Literate programming (and blogging) with Literate.jl

You can use Fredrik Ekre's [Literate.jl](https://github.com/fredrikekre/Literate.jl) package to create Markdown pages suitable for including in your JuDoc workflow. Literate.jl lets you write everything in a Julia source file, including your code, comments, tests, generated plots, and so on. When you execute the Julia file, all your code runs, and you can arrange for Literate.jl to write output such as Markdown-formatted text (and/or Jupyter notebooks) to suitable files.

Literate.jl's syntax relies on various different flavors of comment, some of which are shown in the simple example below.

All non-Julia code has to be commented, of course. Markdown markup language is applied immediately after the first `# `. You can see the `>` Markdown quote syntax and the `##` Markdown header level 2 syntax.

Lines preceded by `#jl` are not included in the Markdown output.

Lines ending with `#src` are evaluated when you run the Julia file, but are not copied into the Markdown output file. Lines beginning with `#src` are Julia comments that don't make it as far as the Markdown file.

You can see from the final five lines that, when you run this file in Julia, the final step is to run the `Literate.markdown` function, taking the name of the Julia source file (`functionoftheweek.jl`) as input, and writing a new Markdown file to the directory `src/pages/` as `fotw_floorceil.md`. Finally, if the JuDoc server is running, you'll find the generated HTML page as `/pub/fotw_floorceil.html`.

`````
#jl This is a Julia source file!

# @def title = "Function of the week: floorceil()"
# @def hascode = true

# > To be, or not to be. That's what they reckon.

# ## Function of the week: floorceil()

# Welcome to another weekly post in which I present a cool Julia function that I've just discovered. This week it's the turn of `floorceil()`. It might sound like something that comes in a tin, but in fact it's a useful function in the Dates module that returns two Dates or DateTimes, one before, and one after, the specified time by a certain unit of time.

# For example:

using Dates

Dates.now()

#
# 2019-05-09T11:29:23.913
#
#src # would be nice if the output from commands could be included!

Dates.floorceil(now(), Dates.Month(1))

#
# (2019-05-01T00:00:00, 2019-06-01T00:00:00)
#

# and you can see that the result contains the beginning and the end of the month that includes the present time of day.

a, b = (Dates.floorceil(now(), Dates.Month(1)));
Dates.canonicalize(Dates.CompoundPeriod(b - a))

#
# 4 weeks, 3 days
#

# That's all for today. Until next time!

#src Lines with this tag appear only in this Julia source file.
using Literate                             #src
Literate.markdown("functionoftheweek.jl",  #src
    "src/pages/",                          #src
    name="fotw_floorceil",                 #src
    documenter=false)                      #src

`````

When this Julia file is executed, the resulting Markdown output will look like the listing below. Notice that the two JuDoc `@def` lines have survived the journey from Julia to Markdown intact, and will now be actively available for the JuDoc generation process.

`````
@def title = "Function of the week: floorceil()"
@def hascode = true

> To be, or not to be. That's what they reckon.

## Function of the week: floorceil()

Welcome to another weekly post in which I present a cool Julia function that I've just discovered. This week it's the turn of `floorceil()`. It might sound like something that comes in a tin, but in fact it's a useful function in the Dates module that returns two Dates or DateTimes, one before, and one after, the specified time by a certain unit of time.

For example:

```julia
using Dates

Dates.now()
```

2019-05-09T11:29:23.913

```julia
Dates.floorceil(now(), Dates.Month(1))
```

(2019-05-01T00:00:00, 2019-06-01T00:00:00)

and you can see that the result contains the beginning and the end of the month that includes the present time of day.

```julia
a, b = (Dates.floorceil(now(), Dates.Month(1)));
Dates.canonicalize(Dates.CompoundPeriod(b - a))
```

4 weeks, 3 days

That's all for today. Until next time!

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*
`````
