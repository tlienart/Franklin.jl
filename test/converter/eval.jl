@testset "Evalcode" begin
    # see `converter/md_blocks:convert_code_block`
    # see `converter/lx/resolve_lx_input_*`
    # --------------------------------------------
    h = raw"""
        Simple code:
        ```julia:./code/exca1
        a = 5
        print(a^2)
        ```
        then:
        \input{output}{./code/exca1}
        done.
        """ * J.EOS |> seval

    h2 = raw"""
        Simple code:
        ```julia:excb1
        a = 5
        print(a^2)
        ```
        then:
        \input{output}{excb1}
        done.
        """ * J.EOS |> seval

    @test h == h2

    spatha = joinpath(J.PATHS[:assets], "index", "code", "exca1.jl")
    spathb = joinpath(J.PATHS[:assets], "index", "code", "excb1.jl")
    @test isfile(spatha)
    @test isfile(spathb)
    @test isapproxstr(read(spatha, String), """
        $(J.MESSAGE_FILE_GEN_JMD)
        a = 5\nprint(a^2)""")

    opath = joinpath(J.PATHS[:assets], "index", "code", "output", "exca1.out")
    @test isfile(opath)
    @test read(opath, String) == "25"

    @test isapproxstr(h, raw"""
            <p>Simple code:
            <pre><code class="language-julia">a = 5
            print(a^2)</code></pre>
            then:
            <pre><code class="plaintext">25</code></pre>
            done.</p>""")
end

@testset "Eval (errs)" begin
    # see `converter/md_blocks:convert_code_block`
    # --------------------------------------------
    h = raw"""
        Simple code:
        ```python:./scripts/testpy
        a = 5
        print(a**2)
        ```
        done.
        """ * J.EOS |> seval

    @test isapproxstr(h, raw"""
            <p>Simple code:
            <pre><code class="language-python">a = 5
            print(a**2)</code></pre>
            done.</p>""")
end

@testset "Eval (rinput)" begin
    h = raw"""
        Simple code:
        ```julia:/assets/scripts/test2
        a = 5
        print(a^2)
        ```
        then:
        \input{output}{/assets/scripts/test2}
        done.
        """ * J.EOS |> seval

    spath = joinpath(J.PATHS[:assets], "scripts", "test2.jl")
    @test isfile(spath)
    @test occursin("a = 5\nprint(a^2)", read(spath, String))

    opath = joinpath(J.PATHS[:assets], "scripts", "output", "test2.out")
    @test isfile(opath)
    @test read(opath, String) == "25"

    @test isapproxstr(h, """
            <p>Simple code:
            <pre><code class="language-julia">a = 5
            print(a^2)</code></pre>
            then:
            <pre><code class="plaintext">25</code></pre>
            done.</p>""")

    # ------------

    J.CUR_PATH[] = "pages/pg1.md"

    h = raw"""
        Simple code:
        ```julia:./code/abc2
        a = 5
        print(a^2)
        ```
        then:
        \input{output}{./code/abc2}
        done.
        """ * J.EOS |> seval

    spath = joinpath(J.PATHS[:assets], "pages", "pg1", "code", "abc2.jl")
    @test isfile(spath)
    @test occursin("a = 5\nprint(a^2)", read(spath, String))

    opath = joinpath(J.PATHS[:assets], "pages", "pg1", "code", "output" ,"abc2.out")
    @test isfile(opath)
    @test read(opath, String) == "25"

    @test isapproxstr(h, """
            <p>Simple code:
            <pre><code class="language-julia">a = 5
            print(a^2)</code></pre>
            then:
            <pre><code class="plaintext">25</code></pre>  done.</p>""")
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
        \input{output}{scripts/test1}
        done.
        """ * J.EOS |> seval
    # dot(a, a) == 54
    @test occursin("""then: <pre><code class="plaintext">54</code></pre> done.""", h)
end

@testset "Eval (img)" begin
    J.CUR_PATH[] = "index.html"
    h = raw"""
        Simple code:
        ```julia:tv2
        write(joinpath(@__DIR__, "output", "tv2.png"), "blah")
        ```
        then:
        \input{plot}{tv2}
        done.
        """ * J.EOS |> seval
    @test occursin("then: <img src=\"/assets/index/code/output/tv2.png\" alt=\"\"> done.", h)
end

@testset "Eval (throw)" begin
    h = raw"""
        Simple code:
        ```julia:scripts/test1
        sqrt(-1)
        ```
        then:
        \input{output}{scripts/test1}
        done.
        """ * J.EOS |> seval
    # errors silently
    @test occursin("then: <pre><code class=\"plaintext\">There was an error running the code:\nDomainError", h)
end

@testset "Eval (nojl)" begin
    h = raw"""
        Simple code:
        ```python:scripts/test1
        sqrt(-1)
        ```
        done.
        """ * J.EOS

    @test (@test_logs (:warn, "Eval of non-julia code blocks is not yet supported.") h |> seval) == "<p>Simple code: <pre><code class=\"language-python\">sqrt(-1)</code></pre> done.</p>\n"
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
        """ * J.EOS |> seval
    @test isapproxstr(h, raw"""
            <p>Simple code: <pre><code class="language-julia">fn = "tempf.jl"
            write(fn, "a = 1+1")
            println("Is this a file? $(isfile(fn))")
            include(abspath(fn))
            println("Now: $a")
            rm(fn)</code></pre> done. <pre><code class="plaintext">Is this a file? true
            Now: 2
            </code></pre></p>
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
        """ |> jd2html_td
    @test isapproxstr(h, """
        <pre><code class="language-julia">a = 5
        a *= 2</code></pre>
        <div class="code_output"><pre><code class="plaintext">10</code></pre></div>
        """)

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
        """ |> jd2html_td
    @test isapproxstr(h, """
        <pre><code class="language-julia">a = 5
        println("hello")
        a *= 2</code></pre>
        <div class="code_output"><pre><code class="plaintext">hello
        10</code></pre></div>
        """)
end
