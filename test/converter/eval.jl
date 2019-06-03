function seval(st)
    J.def_GLOB_VARS!()
    J.def_GLOB_LXDEFS!()
    m, _ = J.convert_md(st, collect(values(J.JD_GLOB_LXDEFS)))
    h = J.convert_html(m, J.JD_VAR_TYPE())
    return h
end

@testset "Eval code" begin
    # see `converter/md_blocks:convert_code_block`
    # see `converter/lx/resolve_input_*`
    # --------------------------------------------
    h = raw"""
        Simple code:
        ```julia:scripts/test1
        a = 5
        print(a^2)
        ```
        then:
        \input{output}{scripts/test1}
        done.
        """ * J.EOS |> seval

    spath = joinpath(J.JD_PATHS[:assets], "scripts", "test1.jl")
    @test isfile(spath)
    @test read(spath, String) == "a = 5\nprint(a^2)\n"

    opath = joinpath(J.JD_PATHS[:assets], "scripts", "output", "test1.out")
    @test isfile(opath)
    @test read(opath, String) == "25"

    @test occursin("code: <pre><code class=\"language-julia\">a = 5\nprint(a^2)</code></pre>", h)
    @test occursin("then: <pre><code>25</code></pre> done.", h)
end

@testset "Eval code (errs)" begin
    # see `converter/md_blocks:convert_code_block`
    # --------------------------------------------
    h = raw"""
        Simple code:
        ```python:scripts/testpy
        a = 5
        print(a**2)
        ```
        done.
        """ * J.EOS |> seval

    @test occursin("code: <pre><code class=\"language-python\">a = 5\nprint(a**2)\n</code></pre> done.", h)
end

@testset "Eval (rel-input)" begin
    h = raw"""
        Simple code:
        ```julia:/scripts/test2
        a = 5
        print(a^2)
        ```
        then:
        \input{output}{/scripts/test2}
        done.
        """ * J.EOS |> seval

    spath = joinpath(J.JD_PATHS[:f], "scripts", "test2.jl")
    @test isfile(spath)
    @test read(spath, String) == "a = 5\nprint(a^2)\n"

    opath = joinpath(J.JD_PATHS[:f], "scripts", "output", "test2.out")
    @test isfile(opath)
    @test read(opath, String) == "25"

    @test occursin("code: <pre><code class=\"language-julia\">a = 5\nprint(a^2)</code></pre>", h)
    @test occursin("then: <pre><code>25</code></pre> done.", h)

    # ------------

    J.JD_CURPATH[] = joinpath(J.JD_PATHS[:in], "pages", "pg1.md")[lastindex(J.JD_PATHS[:in])+2:end]

    h = raw"""
        Simple code:
        ```julia:./code/test2
        a = 5
        print(a^2)
        ```
        then:
        \input{output}{./code/test2}
        done.
        """ * J.EOS |> seval

    spath = joinpath(J.JD_PATHS[:assets], "pages", "code", "test2.jl")
    @test isfile(spath)
    @test read(spath, String) == "a = 5\nprint(a^2)\n"

    opath = joinpath(J.JD_PATHS[:assets], "pages", "code", "output" ,"test2.out")
    @test isfile(opath)
    @test read(opath, String) == "25"

    @test occursin("code: <pre><code class=\"language-julia\">a = 5\nprint(a^2)</code></pre>", h)
    @test occursin("then: <pre><code>25</code></pre> done.", h)
end

@testset "Eval code (module)" begin
    h = raw"""
        Simple code:
        ```julia:scripts/test1
        using LinearAlgebra
        a = [5, 2, 3, 4]
        print(dot(a, a))
        ```
        then:
        \input{output}{scripts/test1}
        done.
        """ * J.EOS |> seval
    # dot(a, a) == 54
    @test occursin("then: <pre><code>54</code></pre> done.", h)
end

@testset "Eval code (img)" begin
    h = raw"""
        Simple code:
        ```julia:scripts/test1
        write(joinpath(@__DIR__, "output", "test1.png"), "blah")
        ```
        then:
        \input{plot}{scripts/test1}
        done.
        """ * J.EOS |> seval
    @test occursin("then: <img src=\"/assets/scripts/output/test1.png\" id=\"judoc-out-plot\"/> done.", h)
end

@testset "Eval code (exception)" begin
    h = raw"""
        Simple code:
        ```julia:scripts/test1
        sqrt(-1)
        ```
        then:
        \input{output}{scripts/test1}
        done.
        """ * J.EOS |> seval
    # errors silently
    @test occursin("then: <pre><code></code></pre>", h)
end
