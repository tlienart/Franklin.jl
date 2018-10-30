@testset "Partial MD" begin
    st = raw"""
        \newcommand{\com}{HH}
        \newcommand{\comb}[1]{HH#1HH}
        A list
        * \com and \comb{blah}
        * $f$ is a function
        * a last element
        """ * J.EOS

    tokens = J.find_tokens(st, J.MD_TOKENS, J.MD_1C_TOKENS)
    blocks, tokens = J.find_md_ocblocks(tokens)
    lxdefs, tokens, braces, blocks = J.find_lxdefs(tokens, blocks)

    @test length(braces) == 1
    @test J.content(braces[1]) == "blah"

    @test length(blocks) == 1
    @test blocks[1].name == :MATH_A
    @test J.content(blocks[1]) == "f"

    lxcoms, _ = J.find_md_lxcoms(tokens, lxdefs, braces)

    blocks2insert = J.merge_blocks(lxcoms, blocks)

    inter_md, mblocks = J.form_inter_md(st, blocks2insert, lxdefs)
    @test inter_md == "\n\nA list\n*  ##JDINSERT##  and  ##JDINSERT## \n*  ##JDINSERT##  is a function\n* a last element\n"
    inter_html = J.md2html(inter_md)
    @test inter_html == "<p>A list</p>\n<ul>\n<li><p>##JDINSERT##  and  ##JDINSERT## </p>\n</li>\n<li><p>##JDINSERT##  is a function</p>\n</li>\n<li><p>a last element</p>\n</li>\n</ul>\n"
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

    tokens = J.find_tokens(st, J.MD_TOKENS, J.MD_1C_TOKENS)
    blocks, tokens = J.find_md_ocblocks(tokens)
    lxdefs, tokens, braces, blocks = J.find_lxdefs(tokens, blocks)
    lxcoms, _ = J.find_md_lxcoms(tokens, lxdefs, braces)

    blocks2insert = J.merge_blocks(lxcoms, blocks)

    inter_md, mblocks = J.form_inter_md(st, blocks2insert, lxdefs)
    @test inter_md == " ##JDINSERT## \nfinally ⊙⊙𝛴⊙ and\n ##JDINSERT## \ndone"
end


@testset "Latex eqa" begin
    st = raw"""
        a\newcommand{\eqa}[1]{\begin{eqnarray}#1\end{eqnarray}}b@@d .@@
        \eqa{\sin^2(x)+\cos^2(x) &=& 1}
        """ * J.EOS

    J.def_JD_LOC_EQDICT()

    tokens = J.find_tokens(st, J.MD_TOKENS, J.MD_1C_TOKENS)
    blocks, tokens = J.find_md_ocblocks(tokens)
    lxdefs, tokens, braces, blocks = J.find_lxdefs(tokens, blocks)
    lxcoms, _ = J.find_md_lxcoms(tokens, lxdefs, braces)

    blocks2insert = J.merge_blocks(lxcoms, blocks)

    inter_md, mblocks = J.form_inter_md(st, blocks2insert, lxdefs)
    @test inter_md == "ab ##JDINSERT## \n ##JDINSERT## \n"

    inter_html = J.md2html(inter_md)
    lxcontext = J.LxContext(lxcoms, lxdefs, braces)

    @test J.convert_block(blocks2insert[1], lxcontext) == "<div class=\"d\">.</div>\n"
    @test J.convert_block(blocks2insert[2], lxcontext) == "\$\$\\begin{array}{c} \\sin^2(x)+\\cos^2(x) &=& 1\\end{array}\$\$"

    hstring = J.convert_inter_html(inter_html, blocks2insert, lxcontext)
    @test hstring == "<p>ab<div class=\"d\">.</div>\n \$\$\\begin{array}{c} \\sin^2(x)+\\cos^2(x) &=& 1\\end{array}\$\$</p>\n"
end


@testset "MD>HTML 1" begin
    st = raw"""
        text A1 \newcommand{\com}{blah}text A2 \com and
        ~~~
        escape B1
        ~~~
        \newcommand{\comb}[ 1]{\mathrm{#1}} text C1 $\comb{b}$ text C2
        \newcommand{\comc}[ 2]{part1:#1 and part2:#2} then \comc{AA}{BB}.
        """ * J.EOS

    tokens = J.find_tokens(st, J.MD_TOKENS, J.MD_1C_TOKENS)
    blocks, tokens = J.find_md_ocblocks(tokens)
    lxdefs, tokens, braces, blocks = J.find_lxdefs(tokens, blocks)
    lxcoms, _ = J.find_md_lxcoms(tokens, lxdefs, braces)

    blocks2insert = J.merge_blocks(lxcoms, blocks)

    inter_md, mblocks = J.form_inter_md(st, blocks2insert, lxdefs)
    @test inter_md == "text A1 text A2  ##JDINSERT##  and\n ##JDINSERT## \n text C1  ##JDINSERT##  text C2\n then  ##JDINSERT## .\n"

    inter_html = J.md2html(inter_md)
    @test inter_html == "<p>text A1 text A2  ##JDINSERT##  and  ##JDINSERT##   text C1  ##JDINSERT##  text C2  then  ##JDINSERT## .</p>\n"
    lxcontext = J.LxContext(lxcoms, lxdefs, braces)
    hstring = J.convert_inter_html(inter_html, blocks2insert, lxcontext)
    @test hstring == "<p>text A1 text A2 blah and \nescape B1\n  text C1 \\(\\mathrm{ b}\\) text C2  then part1: AA and part2: BB.</p>\n"
end


@testset "MD>HTML 2" begin
    st = raw"""
        \newcommand{ \coma }[ 1]{hello #1}
        \newcommand{ \comb} [2 ]{\coma{#1}, goodbye #1, #2!}
        Then \comb{auth1}{auth2}.
        """ * J.EOS

    tokens = J.find_tokens(st, J.MD_TOKENS, J.MD_1C_TOKENS)
    blocks, tokens = J.find_md_ocblocks(tokens)
    lxdefs, tokens, braces, blocks = J.find_lxdefs(tokens, blocks)
    lxcoms, _ = J.find_md_lxcoms(tokens, lxdefs, braces)

    blocks2insert = J.merge_blocks(lxcoms, blocks)

    inter_md, mblocks = J.form_inter_md(st, blocks2insert, lxdefs)
    inter_html = J.md2html(inter_md)
    lxcontext = J.LxContext(lxcoms, lxdefs, braces)
    hstring = J.convert_inter_html(inter_html, mblocks, lxcontext)

    @test inter_md == "\n\nThen  ##JDINSERT## .\n"
    @test hstring == "<p>Then hello   auth1, goodbye  auth1,  auth2&#33;.</p>\n"
end


@testset "Full convert" begin
    st = raw"""
        \newcommand{\E}[1]{\mathbb E\left[#1\right]}
        \newcommand{\eqa}[1]{\begin{eqnarray}#1\end{eqnarray}}
        \newcommand{\R}{\mathbb R}
        Then something like
        \eqa{ \E{f(X)} \in \R &\text{if}& f:\R\maptso\R }
        """ * J.EOS
    m, _ = J.convert_md(st)

    @test m == "<p>Then something like \$\$\\begin{array}{c}  \\mathbb E\\left[ f(X)\\right] \\in \\mathbb R &\\text{if}& f:\\mathbb R\\maptso\\mathbb R \\end{array}\$\$</p>\n"
end


@testset "Brace rge" begin # see #70
    st = raw"""
           \newcommand{\scal}[1]{\left\langle#1\right\rangle}
           \newcommand{\E}{\mathbb E}
           exhibit A
           $\scal{\mu, \nu} = \E[X]$
           exhibit B
           $\E[X] = \scal{\mu, \nu}$
           end.""" * J.EOS
    (m, _) = J.convert_md(st)
    @test m == "<p>exhibit A \\(\\left\\langle \\mu, \\nu\\right\\rangle = \\mathbb E[X]\\) exhibit B \\(\\mathbb E[X] = \\left\\langle \\mu, \\nu\\right\\rangle\\) end.</p>\n"
end


@testset "Insert" begin # see also #65
    st = raw"""
        \newcommand{\com}[1]{⭒!#1⭒}
        abc\com{A}\com{B}def.
        """ * J.EOS
    (m, _) = J.convert_md(st)
    @test m == "<p>abc⭒A⭒⭒B⭒def.</p>\n"

    st = raw"""
        \newcommand{\com}[1]{⭒!#1⭒}
        abc

        \com{A}\com{B}

        def.
        """ * J.EOS
    (m, _) = J.convert_md(st)
    @test m == "<p>abc</p>\n⭒A⭒⭒B⭒\n<p>def.</p>\n"

    st = raw"""
        \newcommand{\com}[1]{⭒!#1⭒}
        abc

        \com{A}

        def.
        """ * J.EOS
    (m, _) = J.convert_md(st)
    @test m == "<p>abc</p>\n⭒A⭒\n<p>def.</p>\n"

    st = raw"""
        \newcommand{\com}[1]{†!#1†}
        blah \com{a}
        * \com{aaa} tt
        * ss \com{bbb}
        """ * J.EOS
    (m, _) = J.convert_md(st)
    @test m == "<p>blah †a†\n<ul>\n<li><p>†aaa† tt</p>\n</li>\n<li><p>ss †bbb†</p>\n</li>\n</ul>\n"
end


@testset "Braces" begin # see also 73
    st = raw"""
        \newcommand{\R}{\mathbb R}
        $$
        	\min_{x\in \R^n} \quad f(x)+i_C(x).
        $$
        """ * J.EOS
    (m, _) = J.convert_md(st)
    @test m == "\$\$\n\t\\min_{x\\in \\mathbb R^n} \\quad f(x)+i_C(x).\n\$\$</p>\n"
end


@testset "CodeblockL" begin
    st = raw"""
    Some code
    ```julia
    struct P
        x::Real
    end
    ```
    done
    """ * JuDoc.EOS
    (m, _) = J.convert_md(st)
    @test m == "<p>Some code <pre><code class=\"language-julia\">struct P\n    x::Real\nend</code></pre>\n done</p>\n"
end


@testset "Deactiv-div" begin # see #74
    st = raw"""
        Etc and `~~~` but hey.
        @@dd but `x` and `y`? @@
        done
        """ * JuDoc.EOS
    (m, _) = J.convert_md(st)
    @test m == "<p>Etc and <code>~~~</code> but hey. <div class=\"dd\">but <code>x</code> and <code>y</code>? </div>\n done</p>\n"
end
