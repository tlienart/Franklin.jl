@testset "unixify" begin
    @test J.unixify("")         == "/"
    @test J.unixify("blah.txt") == "blah.txt"
    @test J.unixify("blah/")    == "blah/"
    @test J.unixify("foo/bar")  == "foo/bar/"
end

@testset "join_rpath" begin
    @test J.join_rpath("blah/blah") == joinpath("blah", "blah")
end

@testset "parse_rpath" begin
    J.PATHS[:folder] = "fld"
    # /[path]
    @test_throws J.RelativePathError J.parse_rpath("/")
    @test J.parse_rpath("/a") == "/a"
    @test J.parse_rpath("/a/b") == "/a/b"
    @test J.parse_rpath("/a/b", canonical=true) == joinpath("fld", "a", "b")
    @test J.parse_rpath("/a/../b", canonical=true) == joinpath("fld", "b")

    # ./[path]
    J.FD_ENV[:CUR_PATH] = joinpath("pages", "pg1.md")
    J.PATHS[:assets] = joinpath("fld", "assets")
    @test_throws J.RelativePathError J.parse_rpath("./")
    @test J.parse_rpath("./a") == "/assets/pages/pg1/a"
    @test J.parse_rpath("./a/b") == "/assets/pages/pg1/a/b"
    @test J.parse_rpath("./a/b", canonical=true) == joinpath("fld", "assets", "pages", "pg1", "a", "b")

    # [path]
    @test_throws J.RelativePathError J.parse_rpath("")
    @test J.parse_rpath("blah") == "/assets/blah"
    @test J.parse_rpath("blah", code=true) == "/assets/pages/pg1/code/blah"
    @test J.parse_rpath("blah", canonical=true) == joinpath("fld", "assets", "blah")
end

@testset "resolve_rpath" begin
    root = J.PATHS[:folder] = mktempdir()
    ass = joinpath(root, "assets")
    mkdir(ass)
    write(joinpath(ass, "p1.jl"), "a = 5")
    write(joinpath(ass, "p2.png"), "gibberish")

    fp, d, fn = J.resolve_rpath("/assets/p1", "julia")
    @test fp == joinpath(ass, "p1.jl")
    @test d == ass
    @test fn == "p1"

    fp, d, fn = J.resolve_rpath("/assets/p2")
    @test fp == joinpath(ass, "p2.png")
    @test d == ass
    @test fn == "p2"

    @test_throws J.FileNotFoundError J.resolve_rpath("/assets/foo")
    @test_throws J.FileNotFoundError J.resolve_rpath("foo")
    @test_throws J.FileNotFoundError J.resolve_rpath("foo", "julia")
end

# @testset "read_snippet" begin
#     root = J.PATHS[:folder] = mktempdir()
#     J.PATHS[:assets] = joinpath(root, "assets")
#     ass = joinpath(root, "assets")
#     mkdir(ass)
#     write(joinpath(ass, "p1.jl"), "a = 5\nb=7")
#     # normal
#     ha, c = J.read_snippet("p1", "julia")
#     @test !ha
#     @test c == "a = 5\nb=7"
#     # other ext
#     write(joinpath(ass, "p2.py"), "gibberish")
#     ha, c = J.read_snippet("p2", "python")
#     @test !ha
#     @test c == "gibberish"
#     # no ext
#     write(joinpath(ass, "p3"), "junk")
#     ha, c = J.read_snippet("p3", "")
#     @test !ha
#     @test c == "junk"
#
#     # with hide
#     write(joinpath(ass, "p4.jl"), """
#         using Random
#         Random.seed!(555) # hide
#         a = 7
#         """)
#     ha, c = J.read_snippet("p4", "julia")
#     @test !ha
#     @test c == "using Random\na = 7"
#
#     # with several hide
#     write(joinpath(ass, "p4.jl"), """
#         using Random
#         Random.seed!(555) # hide
#         a = 7 # HIDE
#         a = 8
#         """)
#     ha, c = J.read_snippet("p4", "julia")
#     @test !ha
#     @test c == "using Random\na = 8"
#
#     # with hideall
#     write(joinpath(ass, "p4.jl"), """
#         #hideall
#         using Random
#         Random.seed!(555)
#         a = 7
#         """)
#     ha, c = J.read_snippet("p4", "julia")
#     @test ha
#     @test c == ""
# end
