@testset "utils" begin
    # Module name
    path = "blah/index.md"
    mn   = F.modulename("blah/index.md")
    @test mn == "FD_SANDBOX_$(hash(path))"
    # New module
    mod = F.newmodule(mn)
    # ismodule
    @test F.ismodule(mn)
    @test !F.ismodule("foobar")
    foobar = 7
    @test !F.ismodule("foobar")
    # eval in module
    Core.eval(mod, Meta.parse("const a=5", 1)[1])
    @test isdefined(mod, :a)
    @test isconst(mod, :a)
    # overwrite module
    mod = F.newmodule(mn)
    @test F.ismodule(mn)
    @test !isdefined(mod, :a)
    Core.eval(mod, Meta.parse("a = 7", 1)[1])
    @test isdefined(mod, :a)
    @test !isconst(mod, :a)
end
