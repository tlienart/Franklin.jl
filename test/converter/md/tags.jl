@testset "tagpages" begin
    fs()
    write(joinpath("_layout", "head.html"), "")
    write(joinpath("_layout", "foot.html"), "")
    write(joinpath("_layout", "page_foot.html"), "")
    write("config.md", "")
    write("index.md", """
        Hello
        """)
    F.def_GLOBAL_VARS!()
    F.def_LOCAL_VARS!()
    write("pg1.md", "@def title = \"Page1\"")
    write("pg2.md", "@def title = \"Page2\"")
    F.set_var!(F.GLOBAL_VARS, "fd_page_tags", F.DTAG(("pg1" => Set(["aa", "bb"]),)))
    F.globvar("fd_page_tags")["pg2"] = Set(["bb", "cc"])

    @test Set(keys(F.globvar("fd_page_tags"))) == Set(["pg1", "pg2"])
    @test Set(union(values(F.globvar("fd_page_tags"))...)) == Set(["aa", "bb", "cc"])

    F.generate_tag_pages()

    @test F.globvar("fd_tag_pages")["aa"] == ["pg1"]
    @test F.globvar("fd_tag_pages")["bb"] == ["pg1","pg2"]
    @test F.globvar("fd_tag_pages")["cc"] == ["pg2"]

    @test isdir(F.path(:tag))
    @test isfile(joinpath(F.path(:tag), "aa", "index.html"))
    @test isfile(joinpath(F.path(:tag), "bb", "index.html"))
    @test isfile(joinpath(F.path(:tag), "cc", "index.html"))

    tagbb = read(joinpath(F.path(:tag), "bb", "index.html"), String)
    tagcc = read(joinpath(F.path(:tag), "cc", "index.html"), String)

    @test occursin("""<ul><li><a href="/pg1/">Page1</a></li><li><a href="/pg2/">Page2</a></li></ul>""", tagbb)
    @test occursin("""<ul><li><a href="/pg2/">Page2</a></li></ul>""", tagcc)

    F.clear_dicts()
end

# ======= INTEGRATION ============

@testset "tags" begin
    fs()
    write(joinpath("_layout", "head.html"), "")
    write(joinpath("_layout", "foot.html"), "")
    write(joinpath("_layout", "page_foot.html"), "")
    write("config.md", "")
    write("index.md", """
        Hello
        """)
    F.def_GLOBAL_VARS!()
    F.def_LOCAL_VARS!()
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
        @def tags = ["aa", "dd", "ee", "ee 00"]
        @def date = Date(2003, 01, 01)
        @def title = "Page 4"
        """)
    serve(clear=true, single=true, cleanup=false, nomess=true)
    @test isdir(joinpath("__site", "tag"))
    for tag in ("aa", "bb", "cc", "dd", "ee", "ee_00")
        local p
        p = joinpath("__site", "tag", tag, "index.html")
        @test isfile(p)
    end

    p = joinpath("__site", "tag", "aa", "index.html")
    c = read(p, String)
    @test occursin("""Tag: aa""", c)
    @test occursin("""<div class=\"franklin-content tagpage\">""", c)
    @test occursin("""<ul><li><a href="/blog/pg4/">Page 4</a></li>""", c)
    @test occursin("""<li><a href="/blog/pg1/">Page 1</a></li></ul>""", c)

    # Now remove some pages; we use bash commands so that they're blocking
    success(`rm $(joinpath("blog", "pg4.md"))`)
    success(`rm $(joinpath("blog", "pg3.md"))`)

    serve(clear=true, single=true, nomess=true)
    c = read(p, String)
    @test occursin("""<div class=\"franklin-content tagpage\">""", c)
    @test occursin("""<ul><li><a href=\"/blog/pg1/\">Page 1</a></li></ul>""", c)

    F.clear_dicts()
end
