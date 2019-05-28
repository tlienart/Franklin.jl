@testset "Eval code" begin
    # see `converter/md_blocks:convert_code_block`
    # see `converter/lx/resolve_input_*`
    # --------------------------------------------
    st = raw"""
        Simple code:
        ```julia:scripts/test1
        a = 5
        print(a^2)
        ```
        then:
        \input{output}{scripts/test1}
        done.
        """ * J.EOS

    J.def_GLOB_VARS!()
    J.def_GLOB_LXDEFS!()

    m, _ = J.convert_md(st, collect(values(J.JD_GLOB_LXDEFS)))
    h = J.convert_html(m, J.JD_VAR_TYPE())

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
    st = raw"""
        Simple code:
        ```python:scripts/testpy
        a = 5
        print(a**2)
        ```
        done.
        """ * J.EOS

    J.def_GLOB_VARS!()
    J.def_GLOB_LXDEFS!()

    # blocks of non-julia code are not yet allowed --> throws a warning and just returns the code
    m, _ = @test_logs (:warn, "Eval of non-julia code blocks is not supported at the moment") J.convert_md(st, collect(values(J.JD_GLOB_LXDEFS)))
    h = J.convert_html(m, J.JD_VAR_TYPE())

    @test occursin("code: <pre><code class=\"language-python\">a = 5\nprint(a**2)\n</code></pre> done.", h)
end
