# Workflow

In this workflow it is assumed that you will eventually host your website on GitHub or GitLab but it shouldn't be hard to adapt to your particular case.

## Local editing

To get started, the easiest is to use the [`newsite`](@ref) to generate a website folder which you can then modify to your heart's content.
The command takes one mandatory argument: the name of the folder, and you can specify a template with `template=...`:

```julia-repl
julia> newsite("Test", template="pure-sm")
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
```

and navigate in a browser to the corresponding address.

## Hosting the website

## Optimisation step

## (git) synchronisation

- publish
- cleanpull
