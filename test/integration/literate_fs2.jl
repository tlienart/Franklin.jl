fs2()

mkpath(F.path(:literate))

@testset "Literate-0" begin
    @test_throws ErrorException literate_folder("foo/")
    litpath = literate_folder("_literate/")
    @test litpath == literate_folder(F.path(:literate))
end

# @testset "Literate-a" begin
#     # Post processing: numbering of julia blocks
#     s = raw"""
#         A
#
#         ```julia
#         B
#         ```
#
#         C
#
#         ```julia
#         D
#         ```
#         """
#     @test F.literate_post_process(s) == """
#         <!--This file was generated, do not modify it.-->
#         A
#
#         ```julia:ex1
#         B
#         ```
#
#         C
#
#         ```julia:ex2
#         D
#         ```
#         """
# end

@testset "Literate-b" begin
    # Literate to Franklin
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
    path = joinpath(F.path(:literate), "tutorial.jl")
    write(path, s)
    opath, = F.literate_to_franklin("/_literate/tutorial")
    @test endswith(opath, joinpath(F.PATHS[:site], "assets", "literate", "tutorial.md"))
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

        \literate{/_literate/tutorial.jl}
        """ |> fd2html_td
    @test isapproxstr(h, """
        <h1 id="rational_numbers"><a href="#rational_numbers">Rational numbers</a></h1>
        <p>In julia rational numbers can be constructed with the <code>//</code> operator. Lets define two rational numbers, <code>x</code> and <code>y</code>:</p>
        <pre><code class="language-julia"># Define variable x and y
        x = 1//3
        y = 2//5</code></pre><pre><code class="plaintext">2//5</code></pre>
        <p>When adding <code>x</code> and <code>y</code> together we obtain a new rational number:</p>
        <pre><code class="language-julia">z = x + y</code></pre><pre><code class="plaintext">11//15</code></pre>
        """)

    # issue 592
    # Literate to Franklin
    s = raw"""
        # # Rational numbers
        # ```julia
        # const a = 1
        # ```
        a = 5
        """
    path = joinpath(F.path(:literate), "tutorial.jl")
    write(path, s)
    opath, = F.literate_to_franklin("/_literate/tutorial")
    @test endswith(opath, joinpath(F.PATHS[:site], "assets", "literate", "tutorial.md"))
    out = read(opath, String)
    @test out // """
        <!--This file was generated, do not modify it.-->
        # Rational numbers
        ```julia
        const a = 1
        ```

        ```julia:ex1
        a = 5
        ```
        """

    # Use of `\literate` command
    h = raw"""
        @def hascode = true
        @def showall = true
        @def reeval = true

        \literate{/_literate/tutorial.jl}
        """ |> fd2html_td
    @test h // """
        <h1 id="rational_numbers"><a href="#rational_numbers">Rational numbers</a></h1>
        <pre><code class="language-julia">const a = 1</code></pre>
        <pre><code class="language-julia">a = 5</code></pre><pre><code class="plaintext">5</code></pre>
        """
end

@testset "Literate-c" begin
    s = raw"""
        \literate{foo}
        """
    @test_throws F.LiterateRelativePathError (s |> fd2html_td)
    s = raw"""
        \literate{/foo}
        """

    global r = ""; s = @capture_out begin
        global r
        r = s |> fd2html_td
    end
    @test r == """<p><span style="color:red;">// Literate file matching '/foo' not found. //</span></p>\n"""
    @test occursin("File not found when", s)
end
