# NEWS

This document keeps track of breaking changes and what you can do if you update and things don't work anymore.

Notes are in reverse chronological order.

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
1. remove `pub/`

(1): since the `pub` disappears, there's also no need for the `pages/` folder but you can keep it if you like.

Then you may have to:

- fix a few of your internal links (use `verify_links()` to help you with that),
- set things up so that the content of  `__site` is what's served on GitHub or elsewhere.

In terms of understanding how the generated paths look, consider the following mappings:

```
`/index.md`         -->     `__site/index.html`
`/index.html`       -->     `__site/index.html`
`/menu1.md`         -->     `__site/menu1/index.html`
`/folder/index.md`  -->     `__site/folder/index.html`
`/folder/page.md`   -->     `__site/folder/page/index.html`
```

This allows to have urls like `www.site.ext/menu1/`.

### v0.5 (JuDoc -> Frankin)

See [the corresponding release notes](https://github.com/tlienart/Franklin.jl/releases/tag/v0.5.0) which include a step-by-step of how to migrate from JuDoc to Franklin.s
