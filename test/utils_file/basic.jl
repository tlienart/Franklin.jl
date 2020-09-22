# Tests for what happens in the `utils.jl`

fs()
write(joinpath("_layout", "head.html"), "")
write(joinpath("_layout", "foot.html"), "")
write(joinpath("_layout", "page_foot.html"), "")
write("config.md", "")

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

    write("utils.jl", """
        function hfun_bar(vname)
            val = locvar(vname[1])
            return round(sqrt(val), digits=2)
        end
        """)
    F.process_utils()
    s = """
        @def xx = 25
        {{bar xx}}
        """ |> fdi
    @test isapproxstr(s, "5.0")
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

    write("utils.jl", """
        function lx_baz(com, _)
            brace_content = Franklin.content(com.braces[1])
            return uppercase(brace_content)
        end
        """)
    F.process_utils()
    s = raw"""
        \baz{bar}
        """ |> fdi
    @test isapproxstr(s, "BAR")
end

# 452
@testset "utils:lxfun2" begin
    write("utils.jl", raw"""
        function lx_bold(com, _)
            text = Franklin.content(com.braces[1])
            return "**$text**"
        end
        """)
    F.process_utils()
    s = raw"""
        \bold{bar}
        """ |> fdi
    @test isapproxstr(s, "<strong>bar</strong>")
end
