@testset "parse fenced" begin
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
