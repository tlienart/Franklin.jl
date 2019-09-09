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

@testset "table" begin
    #
    # has header in source
    #
    testcsv = "h1,h2,h3\nstring1, 1.567, 0\n,,\n l i n e ,.158,99999999"
    write(joinpath(J.PATHS[:assets], "testcsv.csv"), testcsv)
    # no header specified
    h = raw"""
        A table:
        \tableinput{}{/assets/testcsv.csv}
        Done.
        """ |> seval
    shouldbe = """<p>A table: <table><tr><th>h1</th><th>h2</th><th>h3</th></tr>
            <tr><td>string1</td><td>1.567</td><td>0</td></tr>
            <tr><td></td><td></td><td></td></tr>
            <tr><td>l i n e</td><td>.158</td><td>99999999</td></tr></table>
            Done.</p>"""
    @test isapproxstr(h, shouldbe)
    # header specified
    h = raw"""
        A table:
        \tableinput{A,B,C}{/assets/testcsv.csv}
        Done.
        """ |> seval
    shouldbe = """<p>A table: <table><tr><th>A</th><th>B</th><th>C</th></tr>
            <tr><td>h1</td><td>h2</td><td>h3</td></tr>
            <tr><td>string1</td><td>1.567</td><td>0</td></tr>
            <tr><td></td><td></td><td></td></tr>
            <tr><td>l i n e</td><td>.158</td><td>99999999</td></tr></table>
            Done.</p>"""
    @test isapproxstr(h, shouldbe)
    # wrong header
    h = raw"""
        A table:
        \tableinput{,}{/assets/testcsv.csv}
        Done.
        """ |> seval
    shouldbe = """<p>A table: <p><span style=\"color:red;\">// header size (2) and number of columns (3) do not match //</span></p>
            Done.</p>"""
    @test isapproxstr(h, shouldbe)

    #
    # does not have header in source
    #

    testcsv = "string1, 1.567, 0\n,,\n l i n e ,.158,99999999"
    write(joinpath(J.PATHS[:assets], "testcsv.csv"), testcsv)
    # no header specified
    h = raw"""
        A table:
        \tableinput{}{/assets/testcsv.csv}
        Done.
        """ |> seval
    shouldbe = """<p>A table: <table><tr><th>string1</th><th>1.567</th><th>0</th></tr>
            <tr><td></td><td></td><td></td></tr>
            <tr><td>l i n e</td><td>.158</td><td>99999999</td></tr></table>
            Done.</p>"""
    @test isapproxstr(h, shouldbe)
    # header specified
    h = raw"""
        A table:
        \tableinput{A,B,C}{/assets/testcsv.csv}
        Done.
        """ |> seval
    shouldbe = """<p>A table: <table><tr><th>A</th><th>B</th><th>C</th></tr>
            <tr><td>string1</td><td>1.567</td><td>0</td></tr>
            <tr><td></td><td></td><td></td></tr>
            <tr><td>l i n e</td><td>.158</td><td>99999999</td></tr></table>
            Done.</p>"""
    @test isapproxstr(h, shouldbe)
    # wrong header
    h = raw"""
        A table:
        \tableinput{A,B}{/assets/testcsv.csv}
        Done.
        """ |> seval
    shouldbe = """<p>A table: <p><span style=\"color:red;\">// header size (2) and number of columns (3) do not match //</span></p>
            Done.</p>"""
    @test isapproxstr(h, shouldbe)
end
