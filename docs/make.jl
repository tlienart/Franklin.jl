using Documenter, JuDoc, JuDocTemplates

makedocs(
    modules = [JuDoc, JuDocTemplates],
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
             "Workflow" => "man/workflow.md",
             "Syntax" => "man/syntax.md",
             "Templating" => "man/templating.md",
             "Contributing" => "man/contrib.md"
            ],
        "Library" => [
            "Design"    => "lib/design.md",
            "Public"    => "lib/public.md",
            "Internals" => "lib/internals.md",
            ],
        ], # end page
)

deploydocs(
    repo = "github.com/tlienart/JuDoc.jl.git"
)
