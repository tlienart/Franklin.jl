@testset "Input" begin
    #
    # check_input_fname
    #
    F.FD_ENV[:CUR_PATH] = "index.html"
    script1 = joinpath(F.PATHS[:assets], "index", "code", "script1.jl")
    write(script1, "1+1")
    fp, d, fn = F.check_input_rpath("script1.jl", code=true)
    @test fp == script1
    @test d == joinpath(F.PATHS[:assets], "index", "code")
    @test fn == "script1"
    @test_throws ArgumentError F.check_input_rpath("script2.jl")

    #
    # resolve_lx_input_hlcode
    #
    r = F.resolve_lx_input_hlcode("script1.jl", "julia")
    r2 = F.resolve_lx_input_othercode("script1.jl", "julia")
    @test r == "<pre><code class=\"language-julia\">1+1</code></pre>"
    @test r2 == r

    #
    # resolve_lx_input_plainoutput
    #
    mkpath(joinpath(F.PATHS[:assets], "index", "code", "output"))
    plain1 = joinpath(F.PATHS[:assets], "index", "code", "output", "script1.out")
    write(plain1, "2")

    r = F.resolve_lx_input_plainoutput("script1.jl", code=true)
    @test r == "<pre><code class=\"plaintext\">2</code></pre>"
end


@testset "LX input" begin
    write(joinpath(F.PATHS[:assets], "index", "code", "s1.jl"), "println(1+1)")
    write(joinpath(F.PATHS[:assets], "index", "code", "output", "s1a.png"), "blah")
    write(joinpath(F.PATHS[:assets], "index", "code", "output", "s1.out"), "blih")
    st = raw"""
        Some string
        \input{julia}{s1.jl}
        Then maybe
        \input{output:plain}{s1.jl}
        Finally img:
        \input{plot:a}{s1.jl}
        done.
        """;

    F.def_GLOBAL_PAGE_VARS!()
    F.def_GLOBAL_LXDEFS!()

    m, _ = F.convert_md(st, collect(values(F.GLOBAL_LXDEFS)))
    h = F.convert_html(m, F.PageVars())

    @test occursin("<p>Some string <pre><code class=\"language-julia\">$(read(joinpath(F.PATHS[:assets], "index", "code", "s1.jl"), String))</code></pre>", h)
    @test occursin("Then maybe <pre><code class=\"plaintext\">$(read(joinpath(F.PATHS[:assets], "index", "code",  "output", "s1.out"), String))</code></pre>", h)
    @test occursin("Finally img: <img src=\"/assets/index/code/output/s1a.png\" alt=\"\"> done.", h)
end

@testset  "Input MD" begin
    mkpath(joinpath(F.PATHS[:assets], "ccc"))
    fp = joinpath(F.PATHS[:assets], "ccc", "asset1.md")
    write(fp, "blah **blih**")
    st = raw"""
        Some string
        \textinput{ccc/asset1}
        """;
    @test isapproxstr(st |> conv, "<p>Some string blah <strong>blih</strong></p>")
end
