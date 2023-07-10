@testset "repl" begin
    s = """
    ```>
    x = 5
    y = 7 + x
    ```
    some explanation
    ```>
    z = y * 2
    ```
    """ |> fd2html

    @test isapproxstr(s, """
        <pre><code class="language-julia-repl">julia> x &#61; 5
        5
        julia> y &#61; 7 &#43; x
        12
        </code></pre>
        
        <p>some explanation</p>
        <pre><code class="language-julia-repl">
        julia> z &#61; y * 2
        24
        </code></pre>
        """)
end

@testset "help" begin
    s = """
    ```?
    im
    ```
    """ |> fd2html

    @test occursin("""
        <pre><code class="language-julia-repl">help?> im
        </code></pre>
        <div class="julia-help">
        <pre><code>im</code></pre>
        <p>The imaginary unit.</p>
        """, s)
end

@testset "shell" begin
    s = """
        ```;
        echo "foo"
        ```
        """ |> fd2html
    @test isapproxstr(s, """
        <pre><code class="language-julia-repl">shell> echo &quot;foo&quot;
        "foo"
        </code></pre>
        """)
end

@testset "pkg" begin
    s = """
        ```]
        st
        ```
        """ |> fd2html
    @test occursin("""<pre><code class="language-julia-repl">pkg> st""", s)
    @test occursin("""Status `""", s)
end
