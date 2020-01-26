@testset "unixify" begin
    @test F.unixify("")         == "/"
    @test F.unixify("blah.txt") == "blah.txt"
    @test F.unixify("blah/")    == "blah/"
    @test F.unixify("foo/bar")  == "foo/bar/"
end

@testset "join_rpath" begin
    @test F.join_rpath("blah/blah") == joinpath("blah", "blah")
end

@testset "parse_rpath" begin
    F.PATHS[:folder] = "fld"
    # /[path]
    @test_throws F.RelativePathError F.parse_rpath("/")
    @test F.parse_rpath("/a") == "/a"
    @test F.parse_rpath("/a/b") == "/a/b"
    @test F.parse_rpath("/a/b", canonical=true) == joinpath("fld", "a", "b")
    @test F.parse_rpath("/a/../b", canonical=true) == joinpath("fld", "b")

    # ./[path]
    set_curpath(joinpath("pages", "pg1.md"))
    F.PATHS[:assets] = joinpath("fld", "assets")
    @test_throws F.RelativePathError F.parse_rpath("./")
    @test F.parse_rpath("./a") == "/assets/pages/pg1/a"
    @test F.parse_rpath("./a/b") == "/assets/pages/pg1/a/b"
    @test F.parse_rpath("./a/b", canonical=true) == joinpath("fld", "assets", "pages", "pg1", "a", "b")

    # [path]
    @test_throws F.RelativePathError F.parse_rpath("")
    @test F.parse_rpath("blah") == "/assets/blah"
    @test F.parse_rpath("blah", code=true) == "/assets/pages/pg1/code/blah"
    @test F.parse_rpath("blah", canonical=true) == joinpath("fld", "assets", "blah")
end

@testset "resolve_rpath" begin
    root = F.PATHS[:folder] = mktempdir()
    ass  = F.PATHS[:assets] = joinpath(root, "assets")
    mkdir(ass)
    write(joinpath(ass, "p1.jl"), "a = 5")
    write(joinpath(ass, "p2.png"), "gibberish")

    fp, d, fn = F.resolve_rpath("/assets/p1", "julia")
    @test fp == joinpath(ass, "p1.jl")
    @test d == ass
    @test fn == "p1"

    fp, d, fn = F.resolve_rpath("/assets/p2")
    @test fp == joinpath(ass, "p2.png")
    @test d == ass
    @test fn == "p2"

    @test_throws F.FileNotFoundError F.resolve_rpath("/assets/foo")
    @test_throws F.FileNotFoundError F.resolve_rpath("foo")
    @test_throws F.FileNotFoundError F.resolve_rpath("foo", "julia")
end

@testset "form_cpaths" begin
    root = F.PATHS[:folder] = mktempdir()
    ass  = F.PATHS[:assets] = joinpath(root, "assets")
    mkdir(ass)
    curpath = set_curpath(joinpath("pages", "pg1.md"))

    write(joinpath(ass, "p1.jl"), "a = 5")
    write(joinpath(ass, "p2.png"), "gibberish")

    sp, sd, sn, od, op, rp = F.form_codepaths("p1")
    @test sp == joinpath(ass, splitext(curpath)[1], "code", "p1.jl")
    @test sd == joinpath(ass, splitext(curpath)[1], "code")
    @test sn == "p1.jl"
    @test od == joinpath(ass, splitext(curpath)[1], "code", "output")
    @test op == joinpath(od, "p1.out")
    @test rp == joinpath(od, "p1.res")
end
