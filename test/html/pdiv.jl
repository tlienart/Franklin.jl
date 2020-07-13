@testset "simplify-ps" begin
    s = "<p>aa</p>"
    @test F.simplify_ps(s) == "aa"
    s = "<p>aa"
    @test F.simplify_ps(s) == s
    s = "<p>aa<p>b</p>"
    @test F.simplify_ps(s) == s
end

# issue #549
@testset "div-note" begin
    # no nesting
    s = raw"""
    \newcommand{\note}[1]{@@note #1 @@}
    \note{hello}
    """ |> fd2html
    @test s // """
        <div class="note">hello</div>
        """
    # nesting 1 block
    s = raw"""
    \newcommand{\note}[1]{@@note @@title Note @@ #1 @@}
    \note{hello}
    """ |> fd2html
    @test s // """
        <div class="note"><div class="title">Note</div>
        <p>hello</p></div>
        """
    #
    s = raw"""
    \newcommand{\note}[1]{@@note @@title Note @@ @@content #1 @@ @@}
    \note{hello}
    """ |> fd2html
    @test s // """
        <div class="note"><div class="title">Note</div>
        <div class="content">hello</div></div>
        """
end
