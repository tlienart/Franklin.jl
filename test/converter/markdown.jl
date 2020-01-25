@testset "Partial MD" begin
    st = raw"""
        \newcommand{\com}{HH}
        \newcommand{\comb}[1]{HH#1HH}
        A list
        * \com and \comb{blah}
        * $f$ is a function
        * a last element
        """

    steps = explore_md_steps(st)
    lxdefs, tokens, braces, blocks, lxcoms = steps[:latex]

    @test length(braces) == 1
    @test F.content(braces[1]) == "blah"

    @test length(blocks) == 1
    @test blocks[1].name == :MATH_A
    @test F.content(blocks[1]) == "f"

    b2insert, = steps[:b2insert]

    inter_md, mblocks = F.form_inter_md(st, b2insert, lxdefs)
    @test inter_md == "\n\nA list\n*  ##FDINSERT##  and  ##FDINSERT## \n*  ##FDINSERT##  is a function\n* a last element\n"
    inter_html = F.md2html(inter_md)
    @test inter_html == "<p>A list</p>\n<ul>\n<li><p>##FDINSERT##  and  ##FDINSERT## </p>\n</li>\n<li><p>##FDINSERT##  is a function</p>\n</li>\n<li><p>a last element</p>\n</li>\n</ul>\n"
end


# index arithmetic over a string is a bit trickier when using all symbols
# we can use `prevind` and `nextind` to make sure it works properly
@testset "Inter Md 2" begin
    st = raw"""
        ~~~
        this⊙ then ⊙ ⊙ and
        ~~~
        finally ⊙⊙𝛴⊙ and
        ~~~
        escape ∀⊙∀
        ~~~
        done
        """

    inter_md, = explore_md_steps(st)[:inter_md]
    @test inter_md == " ##FDINSERT## \nfinally ⊙⊙𝛴⊙ and\n ##FDINSERT## \ndone\n"
end


@testset "Latex eqa" begin
    st = raw"""
        a\newcommand{\eqa}[1]{\begin{eqnarray}#1\end{eqnarray}}b@@d .@@
        \eqa{\sin^2(x)+\cos^2(x) &=& 1}
        """

    steps = explore_md_steps(st)
    lxdefs, tokens, braces, blocks, lxcoms = steps[:latex]
    b2insert, = steps[:b2insert]
    inter_md, mblocks = steps[:inter_md]
    @test inter_md == "ab ##FDINSERT## \n ##FDINSERT## \n"

    inter_html, = steps[:inter_html]

    @test F.convert_block(b2insert[1], lxdefs) == "<div class=\"d\">.</div>"
    @test isapproxstr(F.convert_block(b2insert[2], lxdefs), "\\[\\begin{array}{c} \\sin^2(x)+\\cos^2(x) &=& 1\\end{array}\\]")
    hstring = F.convert_inter_html(inter_html, b2insert, lxdefs)
    @test isapproxstr(hstring, raw"""
                        <p>
                          ab<div class="d">.</div>
                          \[\begin{array}{c}
                            \sin^2(x)+\cos^2(x) &=& 1
                          \end{array}\]
                        </p>""")
end


@testset "MD>HTML" begin
    st = raw"""
        text A1 \newcommand{\com}{blah}text A2 \com and
        ~~~
        escape B1
        ~~~
        \newcommand{\comb}[ 1]{\mathrm{#1}} text C1 $\comb{b}$ text C2
        \newcommand{\comc}[ 2]{part1:#1 and part2:#2} then \comc{AA}{BB}.
        """

    steps = explore_md_steps(st)
    lxdefs, tokens, braces, blocks, lxcoms = steps[:latex]
    b2insert, = steps[:b2insert]
    inter_md, mblocks = steps[:inter_md]
    inter_html, = steps[:inter_html]

    @test isapproxstr(inter_md, """
                                text A1 text A2  ##FDINSERT##  and
                                ##FDINSERT##
                                text C1  ##FDINSERT##  text C2
                                then  ##FDINSERT## .""")

    @test isapproxstr(inter_html, """<p>text A1 text A2  ##FDINSERT##  and  ##FDINSERT##   text C1  ##FDINSERT##  text C2  then  ##FDINSERT## .</p>""")

    hstring = F.convert_inter_html(inter_html, b2insert, lxdefs)
    @test isapproxstr(hstring, """
                                <p>text A1 text A2 blah and
                                escape B1
                                text C1 \\(\\mathrm{ b}\\) text C2
                                then part1: AA and part2: BB.</p>""")
end


@testset "headers" begin
    set_curpath("index.md")
    h = """
        # Title
        and then
        ## Subtitle cool!
        done
        """ |> seval
    @test isapproxstr(h, """
                        <h1 id="title"><a href="/index.html#title">Title</a></h1>
                        and then
                        <h2 id="subtitle_cool"><a href="/index.html#subtitle_cool">Subtitle cool&#33;</a></h2>
                        done
                        """)
end
