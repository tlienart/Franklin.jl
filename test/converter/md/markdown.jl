
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
    @test inter_md // """
                     ##FDINSERT##
                    finally ⊙⊙𝛴⊙ and
                     ##FDINSERT##
                    done
                    """
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
            text A1 text A2  ##FDINSERT## and
             ##FDINSERT##
             text C1  ##FDINSERT## text C2
             then  ##FDINSERT##.""")

    @test isapproxstr(inter_html, """<p>text A1 text A2  ##FDINSERT## and  ##FDINSERT##  text C1  ##FDINSERT## text C2  then  ##FDINSERT##.</p>""")

    hstring = F.convert_inter_html(inter_html, b2insert, lxdefs)
    @test isapproxstr(hstring, raw"""
                    <p>text A1 text A2 blah and
                    escape B1
                    text C1 \(\mathrm{ b}\) text C2  then part1: AA and part2: BB.</p>""")
end


@testset "headers" begin
    set_curpath("index.md")
    h = """
        # Title
        and then
        ## Subtitle cool!
        done
        """ |> seval
    @test h // """
        <h1 id="title"><a href="#title" class="header-anchor">Title</a></h1>
        <p>and then</p>
        <h2 id="subtitle_cool"><a href="#subtitle_cool" class="header-anchor">Subtitle cool&#33;</a></h2>
        <p>done</p>"""
end
