# issue 505
@testset "mdd+indent" begin
    h = """
        @def x = Dict(
            :a => 5,
            :b => 7
            )
        A
        ```julia:ex
        locvar(:x)[:a]
        ```
        \\show{ex}
        """ |> fd2html
    @test occursin(
        "<code class=\"plaintext code-output\">5</code>", h)
    h = """
        @def x = Dict(
            :a => (1, 2, 3),
            :b => 7
            )
        A
        ```julia:ex
        locvar(:x)[:a][1]
        ```
        \\show{ex}
        """ |> fd2html
    @test occursin(
        "<code class=\"plaintext code-output\">1</code>", h)
    h = """
        @def x = Dict(
            :a => (1,
                   2,
                   3),
            :b => 7
            )
        A
        ```julia:ex
        locvar(:x)[:a][2]
        ```
        \\show{ex}
        """ |> fd2html
    @test occursin(
        "<code class=\"plaintext code-output\">2</code>", h)
end

# Blocks of definitions
@testset "mddefblock" begin
    s = """
        +++
        a = 5
        b = "hello"
        +++
        {{b}} {{a}}
        """ |> fd2html
    # danger of the stuff
    @test isapproxstr(s, "<p>hello 5</p>")
    s = """
        +++
        a = 5
        b = "hello"
        +++
        {{b}} {{a}}
        +++
        a = 7
        +++
        {{a}}
        """ |> fd2html
    @test isapproxstr(s, "<p>hello 7 7</p>")
    # more things
    s = """
       +++
       foo(x, y, z) = x^2 + 2y + z
       out = foo(2,3,4)
       +++
       {{out}}
       """ |> fd2html
    @test isapproxstr(s, "<p>14</p>")
    # errors
    s = """
        +++
        s = sqrt(-1)
        +++
        {{s}}
        """
    @test_throws ErrorException s |> fd2html
end

# blocks of definition with date
@testset "mddefblock+date" begin
    s = """
        +++
        a = 5
        pubdate = Date(2013, 9, 4)
        +++
        {{a}} {{pubdate}}
        """ |> fd2html
    @test isapproxstr(s, "<p> 5 2013-09-04</p>")
end

# windows return
@testset "mddefwindows" begin
    s = "+++\r\na = \"hello\"\r\n+++\r\n# hi\r\n{{a}}" |> fd2html
    @test isapproxstr(s,
        """
        <h1 id=\"hi\"><a href=\"#hi\" class=\"header-anchor\">hi</a></h1>
        hello
        """
    )
end
