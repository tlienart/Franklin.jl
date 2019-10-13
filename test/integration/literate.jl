scripts = joinpath(J.PATHS[:folder], "literate-scripts")
cd(td); J.set_paths!(); mkpath(scripts)

@testset "Literate-0" begin
    @test_throws ErrorException literate_folder("foo/")
    litpath = literate_folder("literate-scripts/")
    @test litpath == joinpath(J.PATHS[:folder], "literate-scripts/")
end

@testset "Literate-a" begin
    # Post processing: numbering of julia blocks
    s = raw"""
        A

        ```julia
        B
        ```

        C

        ```julia
        D
        ```
        """
    @test J.literate_post_process(s) == """
        <!--This file was generated, do not modify it.-->
        A

        ```julia:ex1
        B
        ```

        C

        ```julia:ex2
        D
        ```
        """
end

@testset "Literate-b" begin
    # Literate to JuDoc
    s = raw"""
        # # Rational numbers
        #
        # In julia rational numbers can be constructed with the `//` operator.
        # Lets define two rational numbers, `x` and `y`:

        ## Define variable x and y
        x = 1//3
        y = 2//5

        # When adding `x` and `y` together we obtain a new rational number:

        z = x + y
        """
    path = joinpath(scripts, "tutorial.jl")
    write(path, s)
    opath, = J.literate_to_judoc("/literate-scripts/tutorial")
    @test endswith(opath, joinpath(J.PATHS[:assets], "literate", "tutorial.md"))
    out = read(opath, String)
    @test out == """
        <!--This file was generated, do not modify it.-->
        # Rational numbers

        In julia rational numbers can be constructed with the `//` operator.
        Lets define two rational numbers, `x` and `y`:

        ```julia:ex1
        # Define variable x and y
        x = 1//3
        y = 2//5
        ```

        When adding `x` and `y` together we obtain a new rational number:

        ```julia:ex2
        z = x + y
        ```

        """

    # Use of `\literate` command
    h = raw"""
        @def hascode = true
        @def showall = true
        @def reeval = true

        \literate{/literate-scripts/tutorial.jl}
        """ |> jd2html_td
    @test isapproxstr(h, """
        <h1 id="rational_numbers"><a href="/index.html#rational_numbers">Rational numbers</a></h1>
        <p>In julia rational numbers can be constructed with the <code>//</code> operator. Lets define two rational numbers, <code>x</code> and <code>y</code>:</p>
        <pre><code class="language-julia"># Define variable x and y
        x = 1//3
        y = 2//5</code></pre>
        <div class="code_output"><pre><code class=\"plaintext\">2//5</code></pre></div>
        <p>When adding <code>x</code> and <code>y</code> together we obtain a new rational number:</p>
        <pre><code class="language-julia">z = x + y</code></pre>
        <div class="code_output"><pre><code class=\"plaintext\">11//15</code></pre></div>
        """)
end

@testset "Literate-c" begin
    s = raw"""
        \literate{foo}
        """
    @test_throws ErrorException (s |> jd2html_td)
    s = raw"""
        \literate{/foo}
        """
    @test @test_logs (:warn, "File not found when trying to convert a literate file ($(joinpath(J.PATHS[:folder], "foo.jl"))).") (s |> jd2html_td) == """<p><span style="color:red;">// Literate file matching '/foo' not found. //</span></p></p>\n"""
end
