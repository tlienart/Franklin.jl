using Documenter, JuDoc

makedocs(
    modules = [JuDoc],
    format = Documenter.HTML(
        # Use clean URLs, unless built as a "local" build
        prettyurls = !("local" in ARGS),
        # custom CSS
        assets = ["assets/custom.css"]
        ),
    sitename = "JuDoc.jl",
    authors  = "Thibaut Lienart",
    pages    = [
        "Home" => "index.md",
        "Manual" => [
             "Syntax" => "man/syntax.md",
             "Templating" => "man/templating.md",
             "Workflow" => "man/workflow.md"
            ],
        "Library" => [
            "Public"    => "lib/public.md",
            "Internals" => "lib/internals.md",
            ],
        ], # end page
)

deploydocs(
    repo = "github.com/tlienart/JuDoc.jl.git"
)
