@testset "filecmp" begin
    gotd()

    p1 = joinpath(td, "hello.md")
    p2 = joinpath(td, "bye.md")
    p3 = joinpath(td, "cp1.md")

    write(p1, "foo")
    write(p2, "foo")

    cp(p1, p3)

    @test F.filecmp(p1, p1)
    @test F.filecmp(p1, p2)
    @test F.filecmp(p1, p3)

    write(p2, "baz")
    @test !F.filecmp(p1, p2)

    @test !F.filecmp(p1, "foo/bar")
end
