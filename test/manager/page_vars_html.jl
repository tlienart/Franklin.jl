fs()

@testset "Scope (#412)" begin
    write(joinpath(td, "config.md"), """
        @def title = "config"
        """)
    write(joinpath(td, "page.md"), """
        @def title = "page"
        """)
    write(joinpath(td, "index.html"), """
        {{insert head.html}}
        """)
    mkpath(joinpath(td, "_layout"))
    mkpath(joinpath(td, "_css"))
    write(joinpath(td, "_layout", "head.html"), "<h1>{{fill title}}</h1>")
    write(joinpath(td, "_layout", "page_foot.html"), "")
    write(joinpath(td, "_layout", "foot.html"), "")
    serve(single=true)

    @test startswith(read(joinpath("__site", "index.html"), String),
                        "<h1>config</h1>")
    @test startswith(read(joinpath("__site", "page", "index.html"), String),
                        "<h1>page</h1>")
end
