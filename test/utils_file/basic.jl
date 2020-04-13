# Tests for what happens in the `utils.jl`

fs2()
write(joinpath("_layout", "head.html"), "")
write(joinpath("_layout", "foot.html"), "")
write(joinpath("_layout", "page_foot.html"), "")
write("config.md", "")
fdi(s) = fd2html(s; internal=true)

@testset "utils1" begin
    write("utils.jl", """
        x = 5
        """)
    F.process_utils()
    s = """
        {{fill x}}
        """ |> fdi
    @test isapproxstr(s, "5")
    s = """
        {{x}}
        """ |> fdi
    @test isapproxstr(s, "5")
end

@testset "utils:hfun" begin
    write("utils.jl", """
        hfun_foo() = return "blah"
        """)
    F.process_utils()
    s = """
        {{foo}}
        """ |> fdi
    @test isapproxstr(s, "blah")
end

@testset "utils:lxfun" begin
    write("utils.jl", """
        function lx_foo(lxc::Franklin.LxCom, _)
            return uppercase(Franklin.content(lxc.braces[1]))
        end
        """)
    F.process_utils()
    s = raw"""
        \foo{bar}
        """ |> fdi
    @test isapproxstr(s, "BAR")
end
