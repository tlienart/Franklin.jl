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
