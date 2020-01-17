@testset "utils" begin
    # Module name
    path = "blah/index.md"
    mn   = J.modulename("blah/index.md")
    @test mn == "JD_SANDBOX_$(hash(path))"
    # New module
    mod = J.newmodule(mn)
    # ismodule
    @test J.ismodule(mn)
    @test !J.ismodule("foobar")
    foobar = 7
    @test !J.ismodule("foobar")
    # eval in module
    Core.eval(mod, Meta.parse("const a=5", 1)[1])
    @test isdefined(mod, :a)
    @test isconst(mod, :a)
    # overwrite module
    mod = J.newmodule(mn)
    @test J.ismodule(mn)
    @test !isdefined(mod, :a)
    Core.eval(mod, Meta.parse("a = 7", 1)[1])
    @test isdefined(mod, :a)
    @test !isconst(mod, :a)
end
