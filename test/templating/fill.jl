fs2()
write(joinpath("_layout", "head.html"), "")
write(joinpath("_layout", "foot.html"), "")
write(joinpath("_layout", "page_foot.html"), "")
write("config.md", "")
write("index.md", """
    @def var = 5
    """)
write("page2.md", """
    @def var = 7
    """)

@testset "fill2" begin
    empty!(F.ALL_PAGE_VARS)
    @test F.pagevar("page2", :var) == 7
    @test F.pagevar("index", :var) == 5
    @test F.pagevar("page2.md", :var) == 7
    @test F.pagevar("index.md", :var) == 5
    @test F.pagevar("page2.html", :var) == 7
    @test F.pagevar("index.html", :var) == 5
    s = """
        {{fill var page2}}
        """
    r = fd2html(s; internal=true)
    @test isapproxstr(r, "7")
    s = """
        @def paths = ["page2", "index"]
        {{for p in paths}}
          {{fill var p}}
        {{end}}
        """
    r = fd2html(s; internal=true)
    @test isapproxstr(r, "7 5")
end
