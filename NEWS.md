# NEWS

This document keeps track of breaking changes and key new features and what you can do if you update and things don't work anymore.

Notes are in reverse chronological order.

You can also check out [this issue](https://github.com/tlienart/Franklin.jl/issues/323) with a more granular list of things that are being worked on / have been fixed / added.

### v0.6+ (new functionalities)

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
