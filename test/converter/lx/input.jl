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

    @test occursin("<p>Some string <pre><code class=\"language-julia\">$(F.htmlesc(read(joinpath(F.PATHS[:assets], "index", "code", "s1.jl"), String)))</code></pre>", h)
    @test occursin("Then maybe <pre><code class=\"plaintext\">$(F.htmlesc(read(joinpath(F.PATHS[:assets], "index", "code",  "output", "s1.out"), String)))</code></pre>", h)
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

    @test occursin("<p>Some string <pre><code class=\"language-julia\">$(F.htmlesc(read(joinpath(F.PATHS[:site], "assets", "index", "code", "s1.jl"), String)))</code></pre>", h)
    @test occursin("Then maybe <pre><code class=\"plaintext\">$(F.htmlesc(read(joinpath(F.PATHS[:site], "assets", "index", "code",  "output", "s1.out"), String)))</code></pre>", h)
    @test occursin("Finally img: <img src=\"/assets/index/code/output/s1a.png\" alt=\"\"> done.", h)
end

@testset "Input MD" begin
    mkpath(joinpath(F.PATHS[:site], "assets", "ccc"))
    fp = joinpath(F.PATHS[:site], "assets", "ccc", "asset1.md")
    write(fp, "blah **blih**")
    st = raw"""
        Some string
        \textinput{ccc/asset1}
        """
    @test isapproxstr(st |> conv, "<p>Some string blah <strong>blih</strong></p>")
end

@testset "Input err" begin
    gotd()
    s = raw"""
        AA
        \input{julia}{foo/baz}
        \input{plot}{foo/baz}
        \textinput{foo/bar}
        """ |> fd2html_td
    @test isapproxstr(s, """
        <p>AA
          <p>
            <span style="color:red;">// Couldn't find a file when trying to resolve an input request with relative path: `foo/baz`. //</span>
          </p>
          <p>
            <span style="color:red;">// Couldn't find an output directory associated with 'foo/baz' when trying to input a plot. //</span>
          </p>
          <p>
            <span style="color:red;">// Couldn't find a file when trying to resolve an input request with relative path: `foo/bar`. //</span>
          </p>
        </p>
        """)

    fs2()
    gotd()
    # table input
    mkpath(joinpath(td, "_assets", "index", "output"))
    write(joinpath(td, "_assets", "index", "output", "foo.csv"), "bar")
    s = raw"""
        @def fd_rpath = "index.md"
        \tableinput{}{./foo.csv}
        """ |> fd2html_td
    @test isapproxstr(s, """
        <p><span style="color:red;">// Table matching '/assets/index/foo.csv' not found. //</span></p>
        """)
end
