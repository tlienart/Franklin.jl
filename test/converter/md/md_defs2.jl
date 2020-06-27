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
        "<code class=\"plaintext\">5</code>", h)
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
        "<code class=\"plaintext\">1</code>", h)
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
        "<code class=\"plaintext\">2</code>", h)
end
