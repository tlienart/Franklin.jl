fs()

@testset "fig/rpath" begin
    gotd()

    mkpath(joinpath(td, "__site", "assets", "index"))
    write(joinpath(td, "__site", "assets", "index", "baz.png"), "baz")

    mkpath(joinpath(td, "__site", "assets", "blog", "kaggle"))
    write(joinpath(td, "__site", "assets", "blog", "kaggle", "foo.png"), "foo")

    s = raw"""
        @def fd_rpath = "index.md"
        ABC
        \fig{./baz.png}
        """ |> fd2html_td
    @test isapproxstr(s, """
        <p>ABC <img src="/assets/index/baz.png" alt=""></p>
        """)

    s = raw"""
        @def fd_rpath = "index.md"
        ABC
        \fig{./unknown.png}
        """ |> fd2html_td
    @test isapproxstr(s, """
        <p>ABC <p><span style="color:red;">// Image matching '/assets/index/unknown.png' not found. //</span></p></p>
        """)

    s = raw"""
        @def fd_rpath = "blog/kaggle/index.md"
        ABC
        \fig{./foo.png}
        """ |> fd2html_td
    @test isapproxstr(s, """
        <p>ABC <img src="/assets/blog/kaggle/foo.png" alt=""></p>
        """)

    s = raw"""
        @def fd_rpath = "blog/kaggle/index.md"
        ABC
        \fig{./baz.png}
        """ |> fd2html_td
    @test isapproxstr(s, """
        <p>ABC <p><span style="color:red;">// Image matching '/assets/blog/kaggle/baz.png' not found. //</span></p></p>
        """)
end


@testset "show" begin
    s = """
    @def showall=true
    ```julia:ex
    using DataFrames
    df = DataFrame(A = 1:4, B = ["M", "F", "F", "M"])
    first(df, 3)
    ```
    """ |> fd2html_td
    @test isapproxstr(s, """
        <pre><code class="language-julia">$(F.htmlesc("""
        using DataFrames
        df = DataFrame(A = 1:4, B = ["M", "F", "F", "M"])
        first(df, 3)
        """))</code></pre>
        <pre><code class="plaintext code-output">
        3×2 DataFrame
         Row │ A      B
             │ Int64  String
        ─────┼───────────────
           1 │     1  M
           2 │     2  F
           3 │     3  F
        </code></pre>
        """)
end
