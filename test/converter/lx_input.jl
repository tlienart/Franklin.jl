fs1()

@testset "LX input" begin
    set_curpath("index.md")
    mkpath(joinpath(F.PATHS[:assets], "index", "code", "output"))
    write(joinpath(F.PATHS[:assets], "index", "code", "s1.jl"), "println(1+1)")
    write(joinpath(F.PATHS[:assets], "index", "code", "output", "s1a.png"), "blah")
    write(joinpath(F.PATHS[:assets], "index", "code", "output", "s1.out"), "blih")
    st = raw"""
        Some string
        \input{julia}{s1.jl}
        Then maybe
        \output{s1.jl}
        Finally img:
        \input{plot:a}{s1.jl}
        done.
        """;

    F.def_GLOBAL_VARS!()
    F.def_GLOBAL_LXDEFS!()

    m = F.convert_md(st)
    h = F.convert_html(m)

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
        """
    @test isapproxstr(st |> conv, "<p>Some string blah <strong>blih</strong></p>")
end


fs2()

@testset "LX input" begin
    set_curpath("index.md")
    mkpath(joinpath(F.PATHS[:site], "assets", "index", "code", "output"))
    write(joinpath(F.PATHS[:site], "assets", "index", "code", "s1.jl"), "println(1+1)")
    write(joinpath(F.PATHS[:site], "assets", "index", "code", "output", "s1a.png"), "blah")
    write(joinpath(F.PATHS[:site], "assets", "index", "code", "output", "s1.out"), "blih")
    st = raw"""
        Some string
        \input{julia}{s1.jl}
        Then maybe
        \output{s1.jl}
        Finally img:
        \input{plot:a}{s1.jl}
        done.
        """;

    F.def_GLOBAL_VARS!()
    F.def_GLOBAL_LXDEFS!()

    m = F.convert_md(st)
    h = F.convert_html(m)

    @test occursin("<p>Some string <pre><code class=\"language-julia\">$(read(joinpath(F.PATHS[:site], "assets", "index", "code", "s1.jl"), String))</code></pre>", h)
    @test occursin("Then maybe <pre><code class=\"plaintext\">$(read(joinpath(F.PATHS[:site], "assets", "index", "code",  "output", "s1.out"), String))</code></pre>", h)
    @test occursin("Finally img: <img src=\"/assets/index/code/output/s1a.png\" alt=\"\"> done.", h)
end

@testset  "Input MD" begin
    mkpath(joinpath(F.PATHS[:site], "assets", "ccc"))
    fp = joinpath(F.PATHS[:site], "assets", "ccc", "asset1.md")
    write(fp, "blah **blih**")
    st = raw"""
        Some string
        \textinput{ccc/asset1}
        """
    @test isapproxstr(st |> conv, "<p>Some string blah <strong>blih</strong></p>")
end
