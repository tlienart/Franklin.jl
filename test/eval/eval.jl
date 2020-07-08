fs1()

set_curpath("index.md")

@testset "Evalcode" begin
    h = raw"""
        Simple code:
        ```julia:./code/exca1
        a = 5
        print(a^2)
        ```
        then:

        \output{./code/exca1}

        done.
        """ |> seval

    h2 = raw"""
        Simple code:
        ```julia:excb1
        a = 5
        print(a^2)
        ```
        then:

        \output{excb1}

        done.
        """ |> seval

    @test h == h2

    spatha = joinpath(F.PATHS[:assets], "index", "code", "exca1.jl")
    spathb = joinpath(F.PATHS[:assets], "index", "code", "excb1.jl")
    @test isfile(spatha)
    @test isfile(spathb)
    @test isapproxstr(read(spatha, String), """
        $(F.MESSAGE_FILE_GEN_FMD)
        a = 5\nprint(a^2)""")

    opath = joinpath(F.PATHS[:assets], "index", "code", "output", "exca1.out")
    @test isfile(opath)
    @test read(opath, String) == "25"

    @test isapproxstr(h, raw"""
                <p>Simple code:</p>
                <pre><code class="language-julia">a = 5
                print(a^2)</code></pre>
                <p>then:</p>
                <pre><code class="plaintext">25</code></pre>
                <p>done.</p>""")
end

@testset "Eval (errs)" begin
    s = raw"""
        Simple code:
        ```python:./scripts/testpy
        a = 5
        print(a**2)
        ```
        done.
        """
    h = ""
    @test_logs (:warn, "Evaluation of non-Julia code blocks is not yet supported.") (h = s |> seval)

    @test isapproxstr(h, raw"""
            <p>Simple code:</p>
            <pre><code class="language-python">a = 5
            print(a**2)</code></pre>
            <p>done.</p>""")
end

@testset "Eval (rinput)" begin
    h = raw"""
        Simple code:
        ```julia:/assets/scripts/test2
        a = 5
        print(a^2)
        ```
        then:

        \output{/assets/scripts/test2}

        done.
        """ |> seval

    spath = joinpath(F.PATHS[:assets], "scripts", "test2.jl")
    @test isfile(spath)
    @test occursin("a = 5\nprint(a^2)", read(spath, String))

    opath = joinpath(F.PATHS[:assets], "scripts", "output", "test2.out")
    @test isfile(opath)
    @test read(opath, String) == "25"

    @test isapproxstr(h, """
            <p>Simple code:</p>
            <pre><code class="language-julia">a = 5
            print(a^2)</code></pre>
            <p>then:</p>
            <pre><code class="plaintext">25</code></pre>
            <p>done.</p>""")

    # ------------

    h = raw"""
        @def fd_rpath = "pages/pg1.md"
        Simple code:
        ```julia:./code/abc2
        a = 5
        print(a^2)
        ```
        then:

        \output{./code/abc2}

        done.
        """ |> seval

    spath = joinpath(F.PATHS[:assets], "pages", "pg1", "code", "abc2.jl")
    @test isfile(spath)
    @test occursin("a = 5\nprint(a^2)", read(spath, String))

    opath = joinpath(F.PATHS[:assets], "pages", "pg1", "code", "output" ,"abc2.out")
    @test isfile(opath)
    @test read(opath, String) == "25"

    @test isapproxstr(h, """
            <p>Simple code:</p>
            <pre><code class="language-julia">a = 5
            print(a^2)</code></pre>
            <p>then:</p>
            <pre><code class="plaintext">25</code></pre>
            <p>done.</p>""")
end

@testset "Eval (module)" begin
    h = raw"""
        Simple code:
        ```julia:scripts/test1
        using LinearAlgebra
        a = [5, 2, 3, 4]
        print(dot(a, a))
        ```
        then:

        \output{scripts/test1}

        done.
        """ |> seval
    # dot(a, a) == 54
    @test h // raw"""
                <p>Simple code:</p>
                <pre><code class="language-julia">using LinearAlgebra
                a = [5, 2, 3, 4]
                print(dot(a, a))</code></pre>
                <p>then:</p>
                <pre><code class="plaintext">54</code></pre>
                <p>done.</p>"""
end

@testset "Eval (img)" begin
    h = raw"""
        @def reeval=true
        Simple code:
        ```julia:tv2
        #hideall
        write(joinpath(@OUTPUT, "tv2.png"), "blah")
        ```
        then:

        \input{plot}{tv2}

        done.
        """ |> seval
    @test h // raw"""
                <p>Simple code:</p>

                <p>then:</p>
                <img src="/assets/index/code/output/tv2.png" alt="">
                <p>done.</p>
                """
end

@testset "Eval (throw)" begin
    s = raw"""
        @def reeval=true
        Simple code:
        ```julia:scripts/test1
        sqrt(-1)
        ```
        then:

        \output{scripts/test1}

        done.
        """
    global h
    h = ""
    @test_logs (:warn, "There was an error of type DomainError running the code.") (global h; h = s |> seval)
    # errors silently
    if VERSION >= v"1.2"
        @test h // raw"""
                    <p>Simple code:</p>
                    <pre><code class="language-julia">sqrt(-1)</code></pre>
                    <p>then:</p>
                    <pre><code class="plaintext">DomainError with -1.0:
                    sqrt will only return a complex result if called with a complex argument. Try sqrt(Complex(x)).
                    </code></pre>
                    <p>done.</p>
                    """
    end
end

@testset "Eval (nojl)" begin
    h = raw"""
        Simple code:
        ```python:scripts/test1
        sqrt(-1)
        ```
        done.
        """

    @test (@test_logs (:warn, "Evaluation of non-Julia code blocks is not yet supported.") h |> seval) // raw"""
            <p>Simple code:</p>
            <pre><code class="language-python">sqrt(-1)</code></pre>
            <p>done.</p>"""
end

# temporary fix for 186: make error appear and also use `abspath` in internal include
@testset "eval #186" begin
    h = raw"""
        Simple code:
        ```julia:scripts/test186
        fn = "tempf.jl"
        write(fn, "a = 1+1")
        println("Is this a file? $(isfile(fn))")
        include(abspath(fn))
        println("Now: $a")
        rm(fn)
        ```
        done.

        \output{scripts/test186}
        """ |> seval
    @test isapproxstr(h, raw"""
            <p>Simple code:</p>
            <pre><code class="language-julia">fn = "tempf.jl"
            write(fn, "a = 1+1")
            println("Is this a file? $(isfile(fn))")
            include(abspath(fn))
            println("Now: $a")
            rm(fn)</code></pre>
            <p>done.</p>
            <pre><code class="plaintext">Is this a file? true
            Now: 2
            </code></pre>
            """)
end


@testset "show" begin
    h = raw"""
        @def hascode = true
        @def reeval = true
        ```julia:ex
        a = 5
        a *= 2
        ```

        \show{ex}
        """ |> fd2html_td
    @test h // raw"""
               <pre><code class="language-julia">a = 5
               a *= 2</code></pre>
               <pre><code class="plaintext">10</code></pre>"""

    # Show with stdout
    h = raw"""
        @def hascode = true
        @def reeval = true
        ```julia:ex
        a = 5
        println("hello")
        a *= 2
        ```

        \show{ex}
        """ |> fd2html_td
    @test h // raw"""
                <pre><code class="language-julia">a = 5
                println("hello")
                a *= 2</code></pre>
                <pre><code class="plaintext">hello
                10</code></pre>
                """
end
