fs2()
write(joinpath("_layout", "head.html"), "")
write(joinpath("_layout", "foot.html"), "")
write(joinpath("_layout", "page_foot.html"), "")
write("config.md", "")

@testset "fill2" begin
    write("index.md", """
        @def var = 5
        {{fill var page2}}
        """)
    write("page2.md", """
        @def var = 7
        {{fill var index}}
        """)
    F.serve(single=true, clear=true, cleanup=false)
    index = joinpath("__site", "index.html")
    pg2   = joinpath("__site", "page2", "index.html")
    @test isapproxstr(read(index, String), """
        <div class="franklin-content">7</div>
        """)
    @test isapproxstr(read(pg2, String), """
        <div class="franklin-content">5</div>
        """)
end
