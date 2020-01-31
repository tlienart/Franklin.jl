# see also https://github.com/tlienart/Franklin.jl/issues/330
@testset "locvar" begin
    s = raw"""
        @def va = 5
        @def vb = 7
        ```julia:ex
        #hideall
        println(locvar("va")+locvar("vb"))
        ```
        \output{ex}
        """ |> fd2html_td
    @test isapproxstr(s, """
         <pre><code class="plaintext">12</code></pre>
        """)
end
