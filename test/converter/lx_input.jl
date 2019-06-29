@testset "Input" begin
    #
    # check_input_fname
    #
    script1 = joinpath(J.PATHS[:assets], "script1.jl")
    write(script1, "1+1")
    fp, d, fn = J.check_input_rpath("script1.jl")
    @test fp == script1
    @test d == J.PATHS[:assets]
    @test fn == "script1"
    @test_throws ArgumentError J.check_input_rpath("script2.jl")

    #
    # resolve_lx_input_hlcode
    #
    r = J.resolve_lx_input_hlcode("script1.jl", "julia")
    r2 = J.resolve_lx_input_othercode("script1.jl", "julia")
    @test r == "<pre><code class=\"language-julia\">1+1</code></pre>"
    @test r2 == r

    #
    # resolve_lx_input_plainoutput
    #
    mkpath(joinpath(J.PATHS[:assets], "output"))
    plain1 = joinpath(J.PATHS[:assets], "output", "script1.out")
    write(plain1, "2")

    r = J.resolve_lx_input_plainoutput("script1.jl")
    @test r == "<pre><code>2</code></pre>"
end


@testset "LX input" begin
    write(joinpath(J.PATHS[:assets], "s1.jl"), "println(1+1)")
    write(joinpath(J.PATHS[:assets], "output", "s1a.png"), "blah")
    write(joinpath(J.PATHS[:assets], "output", "s1.out"), "blih")
    st = raw"""
        Some string
        \input{julia}{s1.jl}
        Then maybe
        \input{output:plain}{s1.jl}
        Finally img:
        \input{plot:a}{s1.jl}
        done.
        """ * J.EOS;

    J.def_GLOBAL_PAGE_VARS!()
    J.def_GLOBAL_LXDEFS!()

    m, _ = J.convert_md(st, collect(values(J.GLOBAL_LXDEFS)))
    h = J.convert_html(m, J.PageVars())

    @test occursin("<p>Some string <pre><code class=\"language-julia\">$(read(joinpath(J.PATHS[:assets], "s1.jl"), String))</code></pre>", h)
    @test occursin("Then maybe <pre><code>$(read(joinpath(J.PATHS[:assets], "output", "s1.out"), String))</code></pre>", h)
    @test occursin("Finally img: <img src=\"/assets/output/s1a.png\" alt=\"\"> done.", h)
end
