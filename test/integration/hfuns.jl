@testset "redirect" begin
    gotd()
    write(joinpath(td, "config.md"), "")
    mkpath(joinpath(td, "_css"))
    mkpath(joinpath(td, "_layout"))
    write(joinpath(td, "_layout", "head.html"), "")
    write(joinpath(td, "_layout", "foot.html"), "")
    write(joinpath(td, "_layout", "page_foot.html"), "")
    write(joinpath(td, "foo.md"), """
    {{redirect bar/foo.html}}
    {{redirect bar.html}}
    # Hello
    baz
    """)
    write(joinpath(td, "index.md"), """
    # Index
    """)
    serve(single=true)
    @test isfile(joinpath("__site", "index.html"))
    @test isfile(joinpath("__site", "foo", "index.html"))
    @test isfile(joinpath("__site", "bar.html"))
    @test isfile(joinpath("__site", "bar", "foo.html"))
    @test read(joinpath("__site", "bar", "foo.html"), String) // """
                    <!-- Generated Redirect -->
                    <!doctype html>
                    <html>
                    <head>
                      <meta http-equiv="refresh" content='0; url="/foo/index.html"'>
                    </head>
                    </html>"""
end
