# NEWS

This document keeps track of **key new features**, **breaking changes** and what you can do if you update and things don't work anymore.

You can also check out [this issue](https://github.com/tlienart/Franklin.jl/issues/323) with a more granular list of things that are being worked on / have been fixed / added.

## 0.8+ (ongoing)

* `\underline` is not a thing anymore (I don't think anyone was using it) so that it doesn't clash with KaTeX's underline ([#512](https://github.com/tlienart/Franklin.jl/issues/512)); prefer `\style` for such things.
* files ending with `.min.css` are now **not** minified to avoid rare problems where the minifier would actually break an already minified file ([#494](https://github.com/tlienart/Franklin.jl/issues/494))

## v0.8

This minor releases should have no breaking changes compared to 0.7 apart from a slew of bug fixes.
More people are using Franklin, which is great, that also means more bugs are being found (and eventually fixed), thanks all for your support and patience.

### New stuff

The main new stuff is support for taxonomy. The FranklinTemplates have been updated to reflect this so if you do `newsite("testTaxonomy", template="basic")` you will see that the third menu is now `Tags` and gives some more information on how to  use tags.

At the core you can:

* add tags to pages with `@def tags = ["tag1", "tag2"]`
* if there are any tags present, tag pages will be generated at `/tag/tag1/`, `/tag/tag2/` etc, the layout of tag pages is dictated by `_layout/tag.html` and will essentially contain a list of pages with that tag,
* you can easily customise how that list works by writing your own `hfun_` for the tag-list, check out the templates as suggested above to get an idea for how to do this.

**Important note**: the `_layout/tag.html` **cannot** use local page variables, i.e. things like `{{if hasmath}}` or `{{fill title}}`, that's because it's ambiguous which page would have defined these variables. So you can only use:

* global page variables (defined in `config.md`)
* qualified page variables (`{{fill varname path/to/page/}}`)
* `fd_tag` a special page variable containing the tag string (e.g.: `"tag1"`)

Finally  you can also use `{{ispage /tag/tag1/}}` etc in the `_layout/tag.html` in order to specify a layout that would be dependent upon the tag name.

As usual, your feedback and suggestions are welcome, kindly open issues on GitHub. _Please make it easy for me to help you by giving me as much concise information as possible_.

## v0.7

### Breaking changes

* indented code blocks are now opt-in, prefer fenced code blocks with backticks `` ` ``. This helps avoid ambiguities in parsing. If you do want indented code blocks on a page use `@def indented_code = true`, if you want them everywhere, put that definition in your `config.md`.
* markers for comments now **must** be separated with a character distinct from `-` so `<!--_` is ok, `<!---` is not, `~-->` is ok, `--->` is not. Rule of thumb: use a whitespace.

**Note**: supported Julia versions: 1.3, **1.4**, 1.5.

### New stuff

The main new stuff are:

* you can unpack in template for loops `{{for (x, y, z) in iterator}}`,
* you can use `{{var}}` as a short for `{{fill var}}`, you can use `{{...}}` blocks directly in markdown,
* variable definitions (`@def`) can now be multi-line, the secondary lines **must** be indented,
* you can access page variables from other pages using `{{fill var path}}` where `path` is the relative path to the other file so for instance `{{fill var index}}` or `{{fill var blog/page1}}`, this can be combined with a for loop for instance:

```
@def paths = ["index", "blog/page1"]
{{for p in paths}}
  {{fill var p}}
{{end}}
```

And maybe most importantly, the addition of a `utils.jl` file to complement the `config.md`. In that file you can define variables and functions that can be used elsewhere on your site; they are evaluated in a `Utils` module which is imported in all evaluated code blocks.

* if you define a variable `var = 5`, it will be accessible everywhere, taking priority over any other page variable (including global), you can call `{{fill var}}` or use it in an evaluated code block with `Utils.var`.
* if you define a function `foo() = print("hello")`, you can use it in an evaluated code block with  `Utils.foo()`
* if you define a function `hfun_foo() = return "blah"`, you can use it as a template function `{{foo}}`, they have access to page variable names so this would also be valid:

```julia
function hfun_bar(vname) # vname is a vector of string here
    val = locvar(vname[1])
    return round(sqrt(val), digits=2)
end
```

which you can call with `{{bar var}}`.

* if you define a function `lx_baz` you can use `\baz{...}` and have the function directly act on the input string, the syntax to use must conform to the following example:

```julia
function lx_baz(com, _)
    # keep this first line
    brace_content = Franklin.content(com.braces[1]) # input string
    # Now do whatever you want with the content:
    return uppercase(brace_content)
end
```

which you can call with `\baz{some string}`.



---

## v0.6+

* addition of an `ignore` global page variable to ignore files and directories, addition of a `div_content` page variable to change the name of the main container div.
* Multiline markdown definitions are now allowed, the lines **must** be indented with four spaces e.g. this is ok:

```
@def x = begin
    z = [1,2,3]
    z .+ 3
    end
```

which is a convoluted way of writing

```
@def x = [4,5,6]
```

* template for loop is now available so that you can do this:

```
{{for e in x}}
  {{fill e}}
{{end}}
```

which with the definition above would show `4 5 6` on separate lines.

### v0.6

The most important change is a complete re-vamp of the folder structure resulting from issue #335.

TL;DR: _I just want to keep stuff as they were..._, just add a single line to your `config.md`:

```markdown
@def folder_structure = v"0.1"
```

things should _just work_, and if they don't please open an issue.

---

Now if you want to migrate your site: the "old" folder structure was essentially:

```
.
├── assets
├── css
├── libs
├── pub
└── src
    ├── _css
    ├── _html_parts
    ├── config.md
    ├── index.md
    ├── pages
    └── search.md
```

where the "new" folder structure is now:

```
.
├── __site
├── _assets
├── _css
├── _layout
├── _libs
├── config.md
├── index.md
├── pages
└── search.md
```

where `__site` will contain the full generated site. To migrate from old to new:

1. move `assets` to `_assets`
1. move `src/_css` to `_css`
1. move `src/_html_parts` to `_layout`
1. move `libs` to `_libs`
1. move the rest of the content of `src/` up one level
1. optionally move the content of `pages/` up one level (1)
1. remove `pub/` and `css/`

(1): since the `pub` disappears, there's also no need for the `pages/` folder but you can keep it if you like.

Then you may have to:

- fix links in `_layout/head.html` removing `/pub/` and `.html` so for instance `/pub/menu1.html` becomes `/menu1/`, relative links **must start and end with a `/`**,
- fix a few of your internal links (use `verify_links()` to help you with that),
- set things up so that the content of  `__site` is what's served on GitHub or elsewhere.
- **Note**: links to stylesheets should still be ok, even though the source is now in `_css`, this gets mapped to `__site/css/` and so `/css/somesheet.css` will still work fine.

In terms of understanding how the generated paths look, consider the following mappings:

```
`/index.md`         -->     `__site/index.html`
`/index.html`       -->     `__site/index.html`
`/menu1.md`         -->     `__site/menu1/index.html`
`/folder/index.md`  -->     `__site/folder/index.html`
`/folder/page.md`   -->     `__site/folder/page/index.html`
```

This allows to have urls like `www.site.ext/menu1/`.

Finally note that the deployment of the `__site/` folder is now automated, but to get there you need to set up your repository properly, see the [docs on how to do this](https://franklinjl.org/workflow/deploy/).

**If you encounter issues during the process, open an issue on  GitHub or ask on Slack, I'll try to help and improve these instructions at the same time, thanks!**

### v0.5 (JuDoc -> Frankin)

See [the corresponding release notes](https://github.com/tlienart/Franklin.jl/releases/tag/v0.5.0) which include a step-by-step of how to migrate from JuDoc to Franklin.
