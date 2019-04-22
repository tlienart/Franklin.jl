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
        # "Manual" => [
        #     "Functionalities" => "man/functionalities.md",
        #     "Extending LiveServer" => "man/extending_ls.md"
        #     ],
        "Library" => [
            "Public"    => "lib/public.md",
            "Internals" => "lib/internals.md",
            ],
        ], # end page
)

deploydocs(
    repo = "github.com/asprionj/LiveServer.jl.git"
)
