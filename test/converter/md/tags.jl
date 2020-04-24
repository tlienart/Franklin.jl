fs2()
write(joinpath("_layout", "head.html"), "")
write(joinpath("_layout", "foot.html"), "")
write(joinpath("_layout", "page_foot.html"), "")
write("config.md", "")
write("index.md", """
    Hello
    """)

@testset "tags" begin
    isdir("blog") && rm("blog", recursive=true)
    mkdir("blog")
    write(joinpath("blog", "pg1.md"), """
        @def tags = ["aa", "bb", "cc"]
        @def date = Date(2000, 01, 01)
        @def title = "Page 1"
        """)
    write(joinpath("blog", "pg2.md"), """
        @def tags = ["bb", "cc"]
        @def date = Date(2001, 01, 01)
        @def title = "Page 2"
        """)
    write(joinpath("blog", "pg3.md"), """
        @def tags = ["bb", "cc", "ee", "dd"]
        @def date = Date(2002, 01, 01)
        @def title = "Page 3"
        """)
    write(joinpath("blog", "pg4.md"), """
        @def tags = ["aa", "dd", "ee"]
        @def date = Date(2003, 01, 01)
        @def title = "Page 4"
        """)
    serve(clear=true, single=true, nomess=true)
    @test isdir(joinpath("__site", "tag"))
    for tag in ("aa", "bb", "cc", "dd", "ee")
        local p
        p = joinpath("__site", "tag", tag, "index.html")
        @test isfile(p)
    end
    p = joinpath("__site", "tag", "aa", "index.html")
    c = read(p, String)
    @test isapproxstr(c, """
        <div class="franklin-content">
        <h1>Tag: aa</h1>
        <ul>
          <li><a href="/blog/pg4/">Page 4</a></li>
          <li><a href="/blog/pg1/">Page 1</a></li>
        </ul>
        </div>
        """)

    # Now remove some pages; we use bash commands so that they're blocking
    success(`rm $(joinpath("blog", "pg4.md"))`)
    success(`rm $(joinpath("blog", "pg3.md"))`)

    serve(clear=true, cleanup=false, single=true, nomess=true)
    c = read(p, String)
    @test isapproxstr(c, """
        <div class="franklin-content">
        <h1>Tag: aa</h1>
        <ul>
          <li><a href="/blog/pg1/">Page 1</a></li>
        </ul>
        </div>
        """)
    @test Set(collect(keys(F.globvar("fd_page_tags")))) ==
            Set(["blog/pg1", "blog/pg2"])
    @test Set(union(collect(values(F.globvar("fd_page_tags")))...)) ==
            Set(["aa", "bb", "cc"])
    @test Set(collect(keys(F.globvar("fd_tag_pages")))) ==
            Set(["aa", "bb", "cc"])
    @test Set(union(collect(values(F.globvar("fd_tag_pages")))...)) ==
            Set(["blog/pg1", "blog/pg2"])

    # cleanup
    F.clear_dicts()
end
