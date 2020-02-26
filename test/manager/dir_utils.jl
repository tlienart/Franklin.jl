fs2()

@testset "ignore/fs2" begin
    gotd()
    s = """
        @def ignore = ["foo.md", "path/foo.md", "dir/", "path/dir/"]
        """
    write(joinpath(td, "config.md"), s);
    F.process_config()
    @test F.globvar("ignore") == ["foo.md", "path/foo.md", "dir/", "path/dir/"]

    write(joinpath(td, "foo.md"), "anything")
    mkpath(joinpath(td, "path"))
    write(joinpath(td, "path", "foo.md"), "anything")
    mkpath(joinpath(td, "dir"))
    write(joinpath(td, "dir", "foo1.md"), "anything")
    mkpath(joinpath(td, "path", "dir"))
    write(joinpath(td, "path", "dir", "foo2.md"), "anything")
    write(joinpath(td, "index.md"), "standard things")
    watched = F.fd_setup()
    @test length(watched.md) == 1
    @test first(watched.md).first.second == "index.md"
end

fs1()

@testset "ignore/fs1" begin
    gotd()
    s = """
        @def ignore = ["foo.md", "path/foo.md", "dir/", "path/dir/"]
        """
    mkpath(joinpath(td, "src"))
    write(joinpath(td, "src", "config.md"), s);
    F.process_config()
    @test F.globvar("ignore") == ["foo.md", "path/foo.md", "dir/", "path/dir/"]

    write(joinpath(td, "src", "foo.md"), "anything")
    mkpath(joinpath(td, "src", "path"))
    write(joinpath(td, "src", "path", "foo.md"), "anything")
    mkpath(joinpath(td, "src", "dir"))
    write(joinpath(td, "src", "dir", "foo1.md"), "anything")
    mkpath(joinpath(td, "src", "path", "dir"))
    write(joinpath(td, "src", "path", "dir", "foo2.md"), "anything")
    write(joinpath(td, "src", "index.md"), "standard things")

    mkpath(joinpath(td, "src", "pages"))
    mkpath(joinpath(td, "src", "_css"))
    mkpath(joinpath(td, "src", "_html_parts"))

    watched = F.fd_setup()
    @test length(watched.md) == 1
    @test first(watched.md).first.second == "index.md"
end
