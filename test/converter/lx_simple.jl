@testset "figalt, fig" begin
    write(joinpath(J.PATHS[:assets], "testimg.png"), "png code")
    h = raw"""
        A figure:
        \figalt{fig 1}{/assets/testimg.png}
        \fig{/assets/testimg.png}
        \fig{/assets/testimg}
        Done.
        """ |> seval
    @test isapproxstr(h, """
            <p>A figure:
            <img src=\"/assets/testimg.png\" alt=\"fig 1\">
            <img src=\"/assets/testimg.png\" alt=\"\">
            <img src=\"/assets/testimg.png\" alt=\"\">
            Done.</p>
            """)
    p = mkpath(joinpath(J.PATHS[:assets], "output"))
    write(joinpath(p, "testimg_2.png"), "png code")
    h = raw"""
        Another figure:
        \figalt{fig blah "hello!"}{/assets/testimg_2.png}
        """ |> seval
    @test isapproxstr(h, """
            <p>Another figure:
            <img src=\"/assets/output/testimg_2.png\" alt=\"fig blah $(Markdown.htmlesc("\"hello!\""))\">
            </p>
            """)
    h = raw"""
        No fig:
        \fig{/assets/testimg_3.png}
        """ |> seval
    @test isapproxstr(h, """
            <p>No fig: $(J.html_err("image matching '/assets/testimg_3.png' not found"))</p>
            """)
end

@testset "file" begin
    write(joinpath(J.PATHS[:assets], "blah.pdf"), "pdf code")
    h = raw"""
        View \file{the file}{/assets/blah.pdf} here.
        """ |> seval
    @test isapproxstr(h, """
            <p>View <a href=\"/assets/blah.pdf\">the file</a> here.</p>
            """)
    h = raw"""
        View \file{no file}{/assets/blih.pdf} here.
        """ |> seval
    @test isapproxstr(h, """
            <p>View $(J.html_err("file matching '/assets/blih.pdf' not found")) here.</p>
            """)
end
