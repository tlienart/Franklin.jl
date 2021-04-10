fs()

@testset "ignore/fs2" begin
    gotd()
    s = """
        @def ignore = ["foo.md", "path/foo.md", "dir/", "path/dir/", r"index2.*"]
        """
    write(joinpath(td, "config.md"), s);
    F.process_config()
    @test F.globvar("ignore") == ["foo.md", "path/foo.md", "dir/", "path/dir/", r"index2.*"]

    write(joinpath(td, "foo.md"), "anything")
    mkpath(joinpath(td, "path"))
    write(joinpath(td, "path", "foo.md"), "anything")
    mkpath(joinpath(td, "dir"))
    write(joinpath(td, "dir", "foo1.md"), "anything")
    mkpath(joinpath(td, "path", "dir"))
    write(joinpath(td, "path", "dir", "foo2.md"), "anything")
    write(joinpath(td, "index.md"), "standard things")
    write(joinpath(td, "index2.md"), "anything")
    watched = F.fd_setup()
    @test length(watched.md) == 1
    @test first(watched.md).first.second == "index.md"
end

@testset "coverage" begin
    # form custom output path
    F.def_LOCAL_VARS!()
    path = F.form_custom_output_path("aa/bb")
    @test endswith(F.locvar(:fd_url), "aa/bb/index.html")
    @test isdir(dirname(path))

    # helper functions around regexes
    r1 = r"foo/bar"
    r2 = "foo/bar"
    @test F._access(r1) == r1.pattern
    @test !F._isempty(r1)
    @test !F._isempty(r2)
    @test F._isempty(r"")
    @test F._isempty("")
    @test !F._endswith(r1)
    @test F._endswith("foo/bar/")
    @test F._endswith(r"foo/bar/")
end
