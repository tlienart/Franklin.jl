@testset "lx nesting nomaths" begin
    t = raw"""
        \newcommand{\bar}[1]{A!#1A}
        \newcommand{\dtan}[1]{\bar{!#1}}
        \newcommand{\baz}[2]{#1 / #2}
        \baz{\dtan{x}}{x}
        """ |> fd2html
    @test isapproxstr(t, "AxA / x")
end

@testset "lx nesting maths" begin
    s = raw"""
        \newcommand{\dtan}[1]{\dot{#1}}
        $$\frac{\dtan{a}}{b}$$
        """ |> fd2html
    @test isapproxstr(s, raw"\[\frac{\dot{a}}{b}\]")

    s = raw"""
        \newcommand{\ip}[2]{\langle #1, #2 \rangle}
        $$\ip{\dot{a}}{\dot{b}}$$
        """ |> fd2html
    @test isapproxstr(s, raw"\[\langle \dot{a}, \dot{b} \rangle\]")
end
