fs2()

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
    @test F.parse_rpath("/a/b", canonical=true) == joinpath(F.PATHS[:site], "a", "b")
    @test F.parse_rpath("/a/../b", canonical=true) == joinpath(F.PATHS[:site], "b")

    # ./[path]
    set_curpath("pg1.md")
    @test_throws F.RelativePathError F.parse_rpath("./")
    @test F.parse_rpath("./a") == "/assets/pg1/a"
    @test F.parse_rpath("./a/b") == "/assets/pg1/a/b"
    @test F.parse_rpath("./a/b", canonical=true) == joinpath(F.PATHS[:site], "assets", "pg1", "a", "b")

    # [path]
    @test_throws F.RelativePathError F.parse_rpath("")
    @test F.parse_rpath("blah") == "/assets/blah"
    @test F.parse_rpath("blah", code=true) == "/assets/pg1/code/blah"
    @test F.parse_rpath("blah", canonical=true) == joinpath(F.PATHS[:site], "assets", "blah")
end

@testset "resolve_rpath" begin
    ass = F.PATHS[:assets]
    write(joinpath(ass, "p1.jl"), "a = 5")
    write(joinpath(ass, "p2.png"), "gibberish")
    assout = joinpath(F.PATHS[:site], "assets")
    isdir(assout) && rm(assout, recursive=true)
    mkpath(assout)
    cp(joinpath(ass, "p1.jl"), joinpath(assout, "p1.jl"), force=true)
    cp(joinpath(ass, "p1.jl"), joinpath(assout, "p2.png"), force=true)

    fp, d, fn = F.resolve_rpath("/assets/p1", "julia")
    @test fp == joinpath(assout, "p1.jl")
    @test d == assout
    @test fn == "p1"

    fp, d, fn = F.resolve_rpath("/assets/p2")
    @test fp == joinpath(assout, "p2.png")
    @test d == assout
    @test fn == "p2"

    @test_throws F.FileNotFoundError F.resolve_rpath("/assets/foo")
    @test_throws F.FileNotFoundError F.resolve_rpath("foo")
    @test_throws F.FileNotFoundError F.resolve_rpath("foo", "julia")
end

@testset "form_cpaths" begin
    ass = F.PATHS[:assets]
    assout = joinpath(F.PATHS[:site], "assets")
    isdir(assout) && rm(assout, recursive=true)
    mkpath(assout)

    curpath = set_curpath(joinpath("pages", "pg1.md"))

    write(joinpath(ass, "p1.jl"), "a = 5")
    write(joinpath(ass, "p2.png"), "gibberish")

    sp, sd, sn, od, op, rp = F.form_codepaths("p1")
    @test sp == joinpath(assout, splitext(curpath)[1], "code", "p1.jl")
    @test sd == joinpath(assout, splitext(curpath)[1], "code")
    @test sn == "p1.jl"
    @test od == joinpath(assout, splitext(curpath)[1], "code", "output")
    @test op == joinpath(od, "p1.out")
    @test rp == joinpath(od, "p1.res")
end
