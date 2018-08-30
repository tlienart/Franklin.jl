@testset "MD Blocks" begin
    st = raw"""
        \newcommand{\E}[1]{\mathbb E\left[#1\right]}blah de blah
        ~~~
        escape b1
        ~~~
        \newcommand{\eqa}[1]{\begin{eqnarray}#1\end{eqnarray}}
        \newcommand{\R}{\mathbb R}
        Then something like
        \eqa{ \E{f(X)} \in \R &\text{if}& f:\R\maptso\R }
        and we could try to show latex:
        ```latex
        \newcommand{\brol}{\mathbb B}
        ```
        """ * JuDoc.EOS
    tokens = JuDoc.find_tokens(st, JuDoc.MD_TOKENS, JuDoc.MD_1C_TOKENS)
    tokens = JuDoc.deactivate_xblocks(tokens, JuDoc.MD_EXTRACT)
    bblocks, tokens = JuDoc.find_md_bblocks(tokens)
    lxdefs, tokens = JuDoc.find_md_lxdefs(st, tokens, bblocks)

    @test lxdefs[1].name == "\\E"
    @test lxdefs[1].narg == 1
    @test lxdefs[1].def == "\\mathbb E\\left[#1\\right]"
    @test lxdefs[2].name == "\\eqa"
    @test lxdefs[2].narg == 1
    @test lxdefs[2].def == "\\begin{eqnarray}#1\\end{eqnarray}"
    @test lxdefs[3].name == "\\R"
    @test lxdefs[3].narg == 0
    @test lxdefs[3].def == "\\mathbb R"

    xblocks, tokens = JuDoc.find_md_xblocks(tokens)

    @test xblocks[1].name == :ESCAPE
    @test xblocks[2].name == :CODE

    lxcoms, tokens = JuDoc.find_md_lxcoms(st, tokens, lxdefs, bblocks)

    @test JuDoc.fromto(st, lxcoms[1]) == "\\eqa{ \\E{f(X)} \\in \\R &\\text{if}& f:\\R\\maptso\\R }"
    lxd = getindex(lxcoms[1].lxdef)
    @test lxd.name == "\\eqa"
end


@testset "Find LxComs" begin
    st = raw"""
        \newcommand{\com}{HH}
        \newcommand{\comb}[1]{HH#1HH}
        Blah \com and \comb{blah} etc
        ```julia
        f(x) = x^2
        ```
        etc \comb{blah} then maybe
        @@adiv inner part @@ final.
        """ * JuDoc.EOS

    # Tokenization and Markdown conversion
    tokens = JuDoc.find_tokens(st, JuDoc.MD_TOKENS, JuDoc.MD_1C_TOKENS)
    tokens = JuDoc.deactivate_xblocks(tokens, JuDoc.MD_EXTRACT)
    bblocks, tokens = JuDoc.find_md_bblocks(tokens)
    lxdefs, tokens = JuDoc.find_md_lxdefs(st, tokens, bblocks)
    xblocks, tokens = JuDoc.find_md_xblocks(tokens)
    lxcoms, tokens = JuDoc.find_md_lxcoms(st, tokens, lxdefs, bblocks)
    tokens = filter(τ -> τ.name != :LINE_RETURN, tokens)

    @test JuDoc.fromto(st, lxcoms[1]) == "\\com"
    @test JuDoc.fromto(st, lxcoms[2]) == "\\comb{blah}"

    @test xblocks[1].name == :CODE
    @test xblocks[2].name == :DIV_OPEN
    @test xblocks[3].name == :DIV_CLOSE
end


@testset "Partial MD" begin
    st = raw"""
        \newcommand{\com}{HH}
        \newcommand{\comb}[1]{HH#1HH}
        A list
        * \com and \comb{blah}
        * $f$ is a function
        * a last element
        """ * JuDoc.EOS

    tokens = JuDoc.find_tokens(st, JuDoc.MD_TOKENS, JuDoc.MD_1C_TOKENS)
    tokens = JuDoc.deactivate_xblocks(tokens, JuDoc.MD_EXTRACT)
    bblocks, tokens = JuDoc.find_md_bblocks(tokens)
    lxdefs, tokens = JuDoc.find_md_lxdefs(st, tokens, bblocks)
    xblocks, tokens = JuDoc.find_md_xblocks(tokens)
    lxcoms, tokens = JuDoc.find_md_lxcoms(st, tokens, lxdefs, bblocks)
    tokens = filter(τ -> τ.name != :LINE_RETURN, tokens)
    blocks2insert = JuDoc.merge_xblocks_lxcoms(xblocks, lxcoms)

    inter_md = JuDoc.form_inter_md(st, blocks2insert, lxdefs)
    @test inter_md == "\n\nA list\n* ##JDINSERT## and ##JDINSERT##\n* ##JDINSERT## is a function\n* a last element\n"
    inter_html = JuDoc.md2html(inter_md)
    @test inter_html == "<p>A list</p>\n<ul>\n<li><p>##JDINSERT## and ##JDINSERT##</p>\n</li>\n<li><p>##JDINSERT## is a function</p>\n</li>\n<li><p>a last element</p>\n</li>\n</ul>\n"
end
