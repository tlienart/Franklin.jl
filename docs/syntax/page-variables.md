@def hascode=true

# Page variables

<!--
reviewed: Apr 19, 2020
-->



\blurb{Page variables offer a straightforward way to interact with the HTML templating from the markdown.}

\lineskip

\toc

## Overview

The general syntax to define a page variable is to write `@def varname = value` on a new line e.g.:

```
@def author = "Septimia Zenobia"
```

where you could set the variable to a string, a number, a date,... anything. Definitions can span multiple lines but if they do, the subsequent lines **must** be indented e.g.:

```
@def some_str = """A string
    on several lines is ok
    but lines must be indented"""
```

These variables can serve multiple purposes but, primarily, they can be accessed from the HTML template blocks e.g.:

```html
<footer>
  This is the footer. &copy; {{fill author}}.
</footer>
```

which could be useful as footer on all pages.

The syntax `{{ ... }}` indicates a HTML _function_, `fill` is the function name and the rest of the bracket elements are _page variables_ (here `author`) serving as arguments of the function.

_Local_ page variables denote variables that are defined on a single page and accessible on that page only by contrast to _global_ page variables which are set globally (in the `config.md` file) and accessible on all pages.

In both cases there are _default_ page variables with default values which you can change and use.
You can also define your own variables, both global and local.

### Using page variables

Both local and global page variables are meant for essentially two purposes:

@@tlist
1. control the HTML template from the markdown,
1. modify how Franklin generates HTML.
@@

The second one is a bit less prevalent but, for instance, you can specify the default programming language for all code blocks so that code blocks that don't specify a language would use the default language for highlighting:

```
@def lang = "julia"
```

In the first case, you can access variables in your HTML template via one of the HTML functions such as the `fill` function shown above.

## HTML functions

HTML functions can be used in any one of your `*.html` file and in particular in any of the `_layout/*.html` files such as `head.html`.
They are always called with the syntax `{{fname pv1 pv2 ...}}` where `pv1 pv2 ...` are page variable names.

### Basic functions

A few functions are available with the `{{fill ...}}` arguably the most likely to be of use.

@@lalign
| Format | Role |
| :----: | :--: |
| `{{fill vname}}` or `{{vname}}` | place the value of page variable `vname`
| `{{fill vname rpath}}` | same but taking the value from the page at `rpath` where `rpath` is a relative path like `blog/pg1`
| `{{insert fpath}}` | insert the content of the file at `fpath`
| `{{href  vname}}` | inserts a reference (_mostly internal use_)
| `{{toc}}` | places a table of content (_mostly internal use_)
@@

The `{{insert fpath}}` can be useful if you want to include specific HTML scaffolding on some pages, for instance in example pages you will see in the `head.html`:

```html
{{if hasmath}} {{insert head_katex.html}} {{end}}
```

### Conditional blocks

Conditional blocks allow to specify which parts of the HTML template should be active depending on the value of given page variable(s).
The format follows this structure:

```html
{{if vname}}
...
{{elseif vname2}}
...
{{else}}
...
{{end}}
```

where `vname` and `vname2` are expected to be page variable evaluating to a boolean.
Of course you don't have to specify the `{{elseif ...}}` or `{{else}}` if you don't need them.

\note{
  The conditional blocks are fairly basic; in particular operations between page variables are not supported, so you can't write something like `{{if hasmath && hascode}}`.
  For more complex use cases, consider defining your own HTML functions using the [utils file](/syntax/utils/).
}

You can also use some dedicated conditional blocks:

@@lalign
| Format | Role |
| :----: | :--: |
| `{{ispage path/to/page}}` | whether the current page corresponds to the path
| `{{isnotpage path/to/page}}` | opposite of previous
| `{{isdef vname}}` | whether `vname` is defined
| `{{isnotdef vname}}` | opposite of previous
@@

The `{{ispage ...}}` and `{{isnotpage ...}}` accept `*` as joker symbol; for instance `{{ispage maths/*}}` is allowed.

**Note**: for the `C` users out there, you can also use `ifdef`, `ifndef`.

Consider the following example (very similar to what is used on the current page):

```html
<li class="{{ispage syntax/*}}active{{end}}">• Syntax
<ul>
  <!-- ... -->
  <li class="{{ispage syntax/page-variables}}active{{end}}">Page Variables
  <!-- ... -->
</ul>
```

This allows a simple, javascript-free, way of having a navigation menu that is styled depending on which page is currently active.

### For loops

You can define iterable page variables (array, tuple, ...) and loop over them using the following syntax:

```html
{{for x in vname}}
  ...{{fill x}}...
{{end}}
```

Only `{{fill vname}}` and `{{fill vname rpath}}` are allowed in such a for loop. You can also unpack an iterable like

```html
{{for (x, y) in vname}}
  ...{{fill x}}...{{fill y}}
{{end}}
```

where `vname` would refer to something like `[(1,2),(3,4)]`.

## Global page variables

The table below list global page variables that you can set.
These variables are best defined in your `config.md` file though you can overwrite the value locally by redefining the variable on a given page (this will then only have an effect on that page).

@@lalign
| Name | Type(s) | Default value | Comment
| :--: | :-----: | :-----------: | :-----:
| `author` | `String, Nothing` | `"THE AUTHOR"` |
| `autocode` | `Bool` | `true` | whether to detect the presence of code blocks and set the local var `hascode` automatically
| `automath` | `Bool` | `true` | whether to detect the presence of math blocks and set the local var `hasmath` automatically
| `date_format` | `String`  | `"U dd, yyyy"` | Must be a format recognised by Julia's `Dates.format`
| `date_days` | `Vector{String}`  | `String[]` | Names for days of the week (\*)
| `date_shortdays` | `Vector{String}`  | `String[]` | Short names for the days of the week (\*)
| `date_months` | `Vector{String}`  | `String[]` | Names for months (\*)
| `date_shortmonths` | `Vector{String}`  | `String[]` | Short names for months (\*)
| `div_content` | `String`  | `"franklin-content"` | Name of the div that will englobe the processed content between `head` and `foot`
| `ignore` | `Vector{String}` | `String[]` | Files that should be ignored by Franklin (\*\*)
| `prepath`     | `String`  | `""` | Use if your website is a project website (\*\*\*)
| `website_title`| `String` | `""` | (RSS) (\*\*\*\*)
| `website_descr`| `String` | `""` | (RSS)
| `website_url`  | `String` | `""` | (RSS)
| `generate_rss` | `Bool` | `true` |
| `folder_structure` | `VersionNumber` | `v"0.2"` | only relevant for users of Franklin < 0.5, see [NEWS.md](http://github.com/tlienart/Franklin.jl/NEWS.md)
@@

**Notes**:\\
\smindent{(\*)} \smnote{must be in a format recognized by Julia's `Dates.DateLocale`. Defaults to English. If left unset, the short names are created automatically by using the first three characters of the full names.}\\
\smindent{(\*\*)} \smnote{to ignore a file add it's relative path like `"path/to/file.md"`, to ignore a directory end the path with a `/` like `"path/to/dir/"`.}\\
\smindent{(\*\*\*)} \smnote{say you're using GitHub pages and your username is `darth`, by default Franklin will assume the root URL to  be `darth.github.io/`. However, if you want to build a project page so that the base URL is `darth.github.io/vador/` then use `@def prepath = "vador"`}.\\
\smindent{(\*\*\*\*)} \smnote{these **must** be defined for RSS to be generated for your site (on top of `generate_rss` being `true`). See also the [RSS subsection](#rss) below}.

## Local page variables

The tables below list local page variables that you can set.
These variables are typically set locally on a page.
Remember that:
@@tlist
- you can also define your own variables (with different names),
- you can change the default value of a variable by defining it in your `config.md`.
@@
Note that variables shown below that have a  name starting with  `fd_` are _not meant to be defined_ as their value is  typically  computed  on the fly (but they can be used).

### Basic settings

@@lalign
| Name | Type | Default value | Comment
| ---- | ---- | ------------- | -------
| `title` | `String, Nothing` | `nothing` | page title (\*)
| `hasmath` | `Bool` | `true` | whether to activate KaTeX for that page
| `hascode` | `Bool` | `false` | whether to activate highlight.js for that page
| `date`    | `String, Date, Nothing` | `Date(1)` | a date object (e.g. if you want to set a publication date)
| `lang` | `String` | `julia` | default highlighting for code on the page
| `reflinks` | `Bool` | `true`  | whether there are things like `[ID]: URL` on your page (\*\*)
| `indented_code` | `Bool` | `false` | whether indented blocks should be considered as code (\*\*\*)
| `mintoclevel` | `Int` | `1` | minimum title level to go in the table of content (often you'll want this to  be `2`)
| `maxtoclevel` | `Int` | `10` | maximum title level to go in the table of content
| `fd_ctime` | `String` |  | time of creation of the markdown file
| `fd_mtime` | `String` |  | time of last modification of the markdown file
| `fd_rpath` | `String` |  | relative path to file `[(...)/thispage.md]`
@@

**Notes**:\\
\smindent{(\*)} \smnote{if the title is not set, the first header will be used as title}.\\
\smindent{(\*\*)} \smnote{there may  be cases where you want to literally type `]:` in some code without it indicating a link reference. In such case, set `reflinks` to `false` to avoid ambiguities}.\\
\smindent{(\*\*\*)} \smnote{it is recommended to fence your code blocks (use backticks) as it's not ambiguous for the parser whereas indented blocks can be. If you do want to use indented blocks as code blocks, it's your responsibility to make sure there are no ambiguities}.

### Code evaluation

For more informations on these, see the section on [inserting and evaluating code](/code/).

@@lalign
| Name | Type | Default value | Comment
| ---- | ---- | ------------- | -------
| `reeval` | `Bool` | `false` | whether to reevaluate all code blocks on the page
| `showall` | `Bool` | `false` | notebook mode if `true` where the output of the code block is shown below
| `fd_eval` | `Bool` | `false` | internal variable to keep track of whether the scope is stale (in which case all subsequent blocks are re-evaluated)
@@

### RSS

These are variables related to [RSS 2.0 specifications](https://cyber.harvard.edu/rss/rss.html)  and must match the format indicated there.
If you want proper RSS to be generated, you **must** define at least the `rss_description` or `rss` (which is an alias for `rss_description`).
All these variables expect a `String`.

@@lalign
| Name | Default value |
| ---- | ------------- |
| `rss`, `rss_description` | `""` |
| `rss_title` | current page title |
| `rss_author` | current author |
| `rss_category` | `""` |
| `rss_comments` | `""` |
| `rss_enclosure` | `""` |
| `rss_pubdate`   | `""` |
@@

To recapitulate, for a working RSS feed to be generated you need:

@@tlist
- to set the `website_*` variables in your  `config.md` (see [global page variables](#global_page_variables)),
- on appropriate pages, to define at least `rss` to a valid description.
@@

For an example, see [this mirror of the Julia blog posts](https://github.com/cormullion/julialangblog) with:

@@tlist
- [the config file](https://github.com/cormullion/julialangblog/blob/master/src/config.md)
- an [example of page](https://github.com/cormullion/julialangblog/blob/master/src/pages/2012-02-14-why-we-created-julia.md).
@@
