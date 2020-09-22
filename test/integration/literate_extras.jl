fs()

@testset "(no)show" begin
    lit = raw"""
        # A

        1 + 1

        # B

        2^2;

        # C

        println("hello")

        # done.
        """
    lp = mkpath(joinpath(F.PATHS[:folder], "_literate"))
    write(joinpath(lp, "ex1.jl"), lit)

    s = raw"""
        @def showall = true
        INI

        \literate{/_literate/ex1}
        """

    h = s |> fd2html_td
    @test isapproxstr(h, """
        <p>INI</p>
        <p>A</p>
        <pre><code class="language-julia">$(F.htmlesc(raw"""1 + 1"""))</code></pre><pre><code class="plaintext">2</code></pre>
        <p>B</p>
        <pre><code class="language-julia">$(F.htmlesc(raw"""2^2;"""))</code></pre>
        <p>C</p>
        <pre><code class="language-julia">$(F.htmlesc(raw"""println("hello")"""))</code></pre><pre><code class="plaintext">hello
        </code></pre>
        <p>done.</p>
        """)
end
