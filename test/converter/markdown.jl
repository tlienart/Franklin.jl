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
    lxdefs, tokens = JuDoc.find_md_lxdefs(tokens, bblocks)
    xblocks, tokens = JuDoc.find_md_xblocks(tokens)
    lxcoms, tokens = JuDoc.find_md_lxcoms(tokens, lxdefs, bblocks)
    tokens = filter(τ -> τ.name != :LINE_RETURN, tokens)
    blocks2insert = JuDoc.merge_xblocks_lxcoms(xblocks, lxcoms)

    inter_md = JuDoc.form_inter_md(st, blocks2insert, lxdefs)
    @test inter_md == "\n\nA list\n* ##JDINSERT## and ##JDINSERT##\n* ##JDINSERT## is a function\n* a last element\n"
    inter_html = JuDoc.md2html(inter_md)
    @test inter_html == "<p>A list</p>\n<ul>\n<li><p>##JDINSERT## and ##JDINSERT##</p>\n</li>\n<li><p>##JDINSERT## is a function</p>\n</li>\n<li><p>a last element</p>\n</li>\n</ul>\n"
end


@testset "Latex eqa" begin
    st = raw"""a\newcommand{\eqa}[1]{\begin{eqnarray}#1\end{eqnarray}}b
        \eqa{\sin^2(x)+\cos^2(x) &=& 1}""" * JuDoc.EOS
    tokens = JuDoc.find_tokens(st, JuDoc.MD_TOKENS, JuDoc.MD_1C_TOKENS)
    tokens = JuDoc.deactivate_xblocks(tokens, JuDoc.MD_EXTRACT)
    bblocks, tokens = JuDoc.find_md_bblocks(tokens)
    lxdefs, tokens = JuDoc.find_md_lxdefs(tokens, bblocks)
    xblocks, tokens = JuDoc.find_md_xblocks(tokens)
    lxcoms, tokens = JuDoc.find_md_lxcoms(tokens, lxdefs, bblocks)
    tokens = filter(τ -> τ.name != :LINE_RETURN, tokens)
    blocks2insert = JuDoc.merge_xblocks_lxcoms(xblocks, lxcoms)

    inter_md = JuDoc.form_inter_md(st, blocks2insert, lxdefs)
    @test inter_md == "ab\n##JDINSERT##"

    inter_html = JuDoc.md2html(inter_md)
    lxcontext = JuDoc.LxContext(lxcoms, lxdefs, bblocks)
    hstring = JuDoc.convert_inter_html(inter_html, blocks2insert, lxcontext)
    @test hstring == "<p>ab \$\$\\begin{array}{c}\\sin^2(x)+\\cos^2(x) &=& 1\\end{array}\$\$</p>\n"
end


@testset "MD>HTML 1" begin
    st = raw"""
        text A1 \newcommand{\com}{blah}text A2 \com and
        ~~~
        escape B1
        ~~~
        \newcommand{\comb}[ 1]{\mathrm{#1}} text C1 $\comb{b}$ text C2
        \newcommand{\comc}[ 2]{part1:#1 and part2:#2} then \comc{AA}{BB}.
        """ * JuDoc.EOS

    tokens = JuDoc.find_tokens(st, JuDoc.MD_TOKENS, JuDoc.MD_1C_TOKENS)
    tokens = JuDoc.deactivate_xblocks(tokens, JuDoc.MD_EXTRACT)
    bblocks, tokens = JuDoc.find_md_bblocks(tokens)
    lxdefs, tokens = JuDoc.find_md_lxdefs(tokens, bblocks)
    xblocks, tokens = JuDoc.find_md_xblocks(tokens)
    lxcoms, tokens = JuDoc.find_md_lxcoms(tokens, lxdefs, bblocks)
    tokens = filter(τ -> τ.name != :LINE_RETURN, tokens)
    blocks2insert = JuDoc.merge_xblocks_lxcoms(xblocks, lxcoms)

    inter_md = JuDoc.form_inter_md(st, blocks2insert, lxdefs)
    @test inter_md == "text A1 text A2 ##JDINSERT## and\n##JDINSERT##\n text C1 ##JDINSERT## text C2\n then ##JDINSERT##.\n"

    inter_html = JuDoc.md2html(inter_md)
    @test inter_html == "<p>text A1 text A2 ##JDINSERT## and ##JDINSERT##  text C1 ##JDINSERT## text C2  then ##JDINSERT##.</p>\n"
    lxcontext = JuDoc.LxContext(lxcoms, lxdefs, bblocks)
    hstring = JuDoc.convert_inter_html(inter_html, blocks2insert, lxcontext)
    @test hstring == "<p>text A1 text A2 blah and ~~~\nescape B1\n~~~  text C1 \\(\\mathrm{b}\\) text C2  then part1:AA and part2:BB.</p>\n"
end


@testset "MD>HTML 2" begin
    st = raw"""
        \newcommand{ \coma }[ 1]{hello #1}
        \newcommand{ \comb} [2 ]{\coma{#1}, goodbye #1, #2!}
        Then \comb{auth1}{auth2}.
        """ * JuDoc.EOS
    tokens = JuDoc.find_tokens(st, JuDoc.MD_TOKENS, JuDoc.MD_1C_TOKENS)
    tokens = JuDoc.deactivate_xblocks(tokens, JuDoc.MD_EXTRACT)
    bblocks, tokens = JuDoc.find_md_bblocks(tokens)
    lxdefs, tokens = JuDoc.find_md_lxdefs(tokens, bblocks)
    xblocks, tokens = JuDoc.find_md_xblocks(tokens)
    lxcoms, tokens = JuDoc.find_md_lxcoms(tokens, lxdefs, bblocks)
    tokens = filter(τ -> τ.name != :LINE_RETURN, tokens)
    blocks2insert = JuDoc.merge_xblocks_lxcoms(xblocks, lxcoms)

    inter_md = JuDoc.form_inter_md(st, blocks2insert, lxdefs)
    inter_html = JuDoc.md2html(inter_md)
    lxcontext = JuDoc.LxContext(lxcoms, lxdefs, bblocks)
    hstring = JuDoc.convert_inter_html(inter_html, blocks2insert, lxcontext)

    @test inter_md == "\n\nThen ##JDINSERT##.\n"
    @test hstring == "<p>Then hello auth1, goodbye auth1, auth2&#33;.</p>\n"
end


@testset "Full convert" begin
    st = raw"""
        \newcommand{\E}[1]{\mathbb E\left[#1\right]}
        \newcommand{\eqa}[1]{\begin{eqnarray}#1\end{eqnarray}}
        \newcommand{\R}{\mathbb R}
        Then something like
        \eqa{ \E{f(X)} \in \R &\text{if}& f:\R\maptso\R }
        """ * JuDoc.EOS
    m, _ = JuDoc.convert_md(st)

    @test m == "<p>Then something like \$\$\\begin{array}{c} \\mathbb E\\left[f(X)\\right] \\in \\mathbb R &\\text{if}& f:\\mathbb R\\maptso\\mathbb R \\end{array}\$\$</p>\n"
end
