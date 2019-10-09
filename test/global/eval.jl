# This set of tests is specifically for the ordering
# of operations, when code blocks are eval-ed or re-eval-ed

@testset "EvalOrder" begin
    flush_td(); set_globals()

    Random.seed!(0) # seed for extra testing of when code is ran
    # Generate random numbers in a sequence then we'll check
    # things are done in the same sequence on the page
    a, b, c, d, e = randn(5)
    Random.seed!(0)

    # Create a page "foo.md" which we'll use and abuse
    foo = raw"""
        @def hascode = true
        ```julia:ex
        println(randn())
        ```
        \output{ex}
        """

    # FIRST PASS --> EVAL

    h = foo |> jd2html_td

    @test isapproxstr(h, """
                <pre><code class="language-julia">println(randn())</code></pre> <pre><code class=\"plaintext\">$a</code></pre>
                """)

    # TEXT MODIFICATION + IN SCOPE --> NO REEVAL

    foo *= "etc"

    h = foo |> jd2html_td

    @test isapproxstr(h, """
                <pre><code class="language-julia">println(randn())</code></pre> <pre><code class=\"plaintext\">$a</code></pre> etc
                """)

    # CODE ADDITION + IN SCOPE --> NO REEVAL OF FIRST BLOCK

    foo *= raw"""
        ```julia:ex2
        println(randn())
        ```
        \output{ex2}
        ```julia:ex3
        println(randn())
        ```
        \output{ex3}
        """

    h = foo |> jd2html_td

    @test isapproxstr(h, """
                <pre><code class="language-julia">println(randn())</code></pre> <pre><code class=\"plaintext\">$a</code></pre> etc
                <pre><code class="language-julia">println(randn())</code></pre> <pre><code class=\"plaintext\">$b</code></pre>
                <pre><code class="language-julia">println(randn())</code></pre> <pre><code class=\"plaintext\">$c</code></pre>
                """)

    # CODE MODIFICATION + IN SCOPE --> REEVAL OF BLOCK AND AFTER

    foo = raw"""
        @def hascode = true
        ```julia:ex
        println(randn())
        ```
        \output{ex}
        ```julia:ex2
        # modif
        println(randn())
        ```
        \output{ex2}
        ```julia:ex3
        println(randn())
        ```
        \output{ex3}
        """

    h = foo |> jd2html_td

    @test isapproxstr(h, """
                <pre><code class="language-julia">println(randn())</code></pre> <pre><code class=\"plaintext\">$a</code></pre>
                <pre><code class="language-julia"># modif
                println(randn())</code></pre> <pre><code class=\"plaintext\">$d</code></pre>
                <pre><code class="language-julia">println(randn())</code></pre> <pre><code class=\"plaintext\">$e</code></pre>
                """)

    # FROZEN CODE --> WILL USE CODE FROM BEFORE even though we changed it (no re-eval)

    foo = raw"""
        @def hascode = true
        @def freezecode = true
        ```julia:ex
        # modif
        println(randn())
        ```
        \output{ex}
        ```julia:ex2
        println(randn())
        ```
        \output{ex2}
        ```julia:ex3
        println(randn())
        ```
        \output{ex3}
        """

    h = foo |> jd2html_td

    @test isapproxstr(h, """
                <pre><code class="language-julia">println(randn())</code></pre> <pre><code class=\"plaintext\">$a</code></pre>
                <pre><code class="language-julia"># modif
                println(randn())</code></pre> <pre><code class=\"plaintext\">$d</code></pre>
                <pre><code class="language-julia">println(randn())</code></pre> <pre><code class=\"plaintext\">$e</code></pre>
                """)
end

@testset "EvalOrder2" begin
    flush_td(); set_globals()

    # Inserting new code block
    h = raw"""
        @def hascode = true
        ```julia:ex1
        a = 5
        println(a)
        ```
        \output{ex1}
        ```julia:ex2
        a += 3
        println(a)
        ```
        \output{ex2}
        """ |> jd2html_td

    @test isapproxstr(h, """
            <pre><code class="language-julia">a = 5
            println(a)</code></pre>
            <pre><code class=\"plaintext\">5</code></pre>
            <pre><code class="language-julia">a += 3
            println(a)</code></pre>
            <pre><code class=\"plaintext\">8</code></pre>
            """)

    @test J.LOCAL_PAGE_VARS["jd_code"].first == """
        a = 5
        println(a)

        a += 3
        println(a)"""

    h = raw"""
        @def hascode = true
        @def reeval  = true
        ```julia:ex1
        a = 5
        println(a)
        ```
        \output{ex1}
        ```julia:ex1b
        a += 1
        println(a)
        ```
        \output{ex1b}
        ```julia:ex2
        a += 3
        println(a)
        ```
        \output{ex2}
        """ |> jd2html_td

    @test isapproxstr(h, """
            <pre><code class="language-julia">a = 5
            println(a)</code></pre>
            <pre><code class=\"plaintext\">5</code></pre>
            <pre><code class="language-julia">a += 1
            println(a)</code></pre>
            <pre><code class=\"plaintext\">6</code></pre>
            <pre><code class="language-julia">a += 3
            println(a)</code></pre>
            <pre><code class=\"plaintext\">9</code></pre>
            """)
    @test J.LOCAL_PAGE_VARS["jd_code"].first == """
        a = 5
        println(a)

        a += 1
        println(a)

        a += 3
        println(a)"""
end
