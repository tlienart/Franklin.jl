# Workflow

In this workflow it is assumed that you will eventually host your website on GitHub or GitLab but it shouldn't be hard to adapt to your particular case.

## Local editing

To get started, the easiest is to use the [`newsite`](@ref) to generate a website folder which you can then modify to your heart's content.
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

and navigate in a browser to the corresponding address.

### Structure

The [`newsite`](@ref) command above generates folders and examples files following the appropriate structure, so the easiest is to start with that and modify in place.
Once you run [`serve`](@ref) the first time, two more folders are generated (`css/` and `pub/`).

Among the folders,

* you should ignore `css/` and `pub/` these are _generated_ and any changes you'd do there will be silently over-written whenever you modify files in `src/`; the same comment holds for `index.html`
* the main folder is `src/` and its subfolders, this is effectively where the source for your site is
* the folders `assets/` and `libs/` contain auxiliary things that are useful for your site: `assets/`  would contain code snippets, images etc and `libs/` would contain javascript libraries that you may need (KaTeX and highlight are in there by  default).

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
The `pages/page1.md` would contain pages (you can have whatever subfolder structure you want in there, and will just have to adapt internal links appropriately).
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

Unsurprisingly, the style sheets in `_css/` will help you adjust tune the way your site looks.
The `judoc.css` is the stylesheet that corresponds more specifically to the styling of the `.jd-content` div and all that goes in it, it tends to be the first style-sheet to be loaded.
The simplest way to adjust the style easily would be to define your own stylesheet `_css/adjustments.css` and it be the last stylesheet loaded in `_html_parts/head.html` so that you can easily overwrite whatever properties you don't like and define your own.

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

## Hosting the website

(assumes github or gitlab)

## Optimisation step

## (git) synchronisation

(assumes you have either git init or hosted the website on github/gitlab etc)

- publish
- cleanpull
