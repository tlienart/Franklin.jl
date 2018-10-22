@testset "Find Tokens" begin
    a = raw"""some markdown then `code` and @@dname block @@""" * JuDoc.EOS

    tokens = JuDoc.find_tokens(a, JuDoc.MD_TOKENS, JuDoc.MD_1C_TOKENS)

    @test tokens[1].name == :CODE_SINGLE
    @test tokens[2].name == :CODE_SINGLE
    @test tokens[3].name == :DIV_OPEN
    @test tokens[3].ss == "@@dname"
    @test tokens[4].ss == "@@"
end


@testset "Find blocks" begin
    st = raw"""
        some markdown then `code` and
        @@dname block @@
        then maybe an escape
        ~~~
        escape block
        ~~~
        and done {target} done.
        """ * JuDoc.EOS

    tokens = JuDoc.find_tokens(st, JuDoc.MD_TOKENS, JuDoc.MD_1C_TOKENS)
    blocks, tokens = JuDoc.find_md_ocblocks(tokens)
    braces = filter(β -> β.name == :LXB, blocks)

    # div block
    β = blocks[1]
    @test β.name == :DIV
    @test β.ss == "@@dname block @@"

    # escape block
    β = blocks[2]
    @test β.name == :ESCAPE
    @test β.ss == "~~~\nescape block\n~~~"

    # inline code block
    β = blocks[3]
    @test β.name == :CODE_INLINE
    @test β.ss == "`code`"

    # brace block
    β = braces[1]
    @test β.name == :LXB
    @test β.ss == "{target}"
end


@testset "Lx defs+coms" begin
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
    blocks, tokens = JuDoc.find_md_ocblocks(tokens)
    lxdefs, tokens, braces, blocks = JuDoc.find_lxdefs(tokens, blocks)

    @test lxdefs[1].name == "\\E"
    @test lxdefs[1].narg == 1
    @test lxdefs[1].def  == "\\mathbb E\\left[#1\\right]"
    @test lxdefs[2].name == "\\eqa"
    @test lxdefs[2].narg == 1
    @test lxdefs[2].def  == "\\begin{eqnarray}#1\\end{eqnarray}"
    @test lxdefs[3].name == "\\R"
    @test lxdefs[3].narg == 0
    @test lxdefs[3].def  == "\\mathbb R"

    @test blocks[1].name == :ESCAPE
    @test blocks[2].name == :CODE_BLOCK_L

    lxcoms, tokens = JuDoc.find_md_lxcoms(tokens, lxdefs, braces)

    @test lxcoms[1].ss == "\\eqa{ \\E{f(X)} \\in \\R &\\text{if}& f:\\R\\maptso\\R }"
    lxd = getindex(lxcoms[1].lxdef)
    @test lxd.name == "\\eqa"
end


@testset "Lxdefs 2" begin
    st = raw"""
        \newcommand{\com}{blah}
        \newcommand{\comb}[ 2]{hello #1 #2}
        """ * JuDoc.EOS

    tokens = JuDoc.find_tokens(st, JuDoc.MD_TOKENS, JuDoc.MD_1C_TOKENS)
    blocks, tokens = JuDoc.find_md_ocblocks(tokens)
    lxdefs, tokens, braces, blocks = JuDoc.find_lxdefs(tokens, blocks)

    @test lxdefs[1].name == "\\com"
    @test lxdefs[1].narg == 0
    @test lxdefs[1].def == "blah"
    @test lxdefs[2].name == "\\comb"
    @test lxdefs[2].narg == 2
    @test lxdefs[2].def == "hello #1 #2"
end


@testset "Lxcoms 2" begin
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

    tokens = JuDoc.find_tokens(st, JuDoc.MD_TOKENS, JuDoc.MD_1C_TOKENS)
    blocks, tokens = JuDoc.find_md_ocblocks(tokens)
    lxdefs, tokens, braces, blocks = JuDoc.find_lxdefs(tokens, blocks)
    lxcoms, _ = JuDoc.find_md_lxcoms(tokens, lxdefs, braces)

    @test lxcoms[1].ss == "\\com"
    @test lxcoms[2].ss == "\\comb{blah}"

    @test blocks[1].name == :DIV
    @test blocks[1].ss == "@@adiv inner part @@"
    @test JuDoc.content(blocks[1]) == " inner part "

    @test blocks[2].name == :CODE_BLOCK_L
    @test blocks[2].ss == "```julia\nf(x) = x^2\n```"
    @test JuDoc.content(blocks[2]) == "\nf(x) = x^2\n"
end


@testset "lxcoms3" begin
    st = raw"""
        text A1 \newcommand{\com}{blah}text A2 \com and
        ~~~
        escape B1
        ~~~
        \newcommand{\comb}[ 1]{\mathrm{#1}} text C1 $\comb{b}$ text C2
        \newcommand{\comc}[ 2]{part1:#1 and part2:#2} then \comc{AA}{BB}.
        """ * JuDoc.EOS

    tokens = JuDoc.find_tokens(st, JuDoc.MD_TOKENS, JuDoc.MD_1C_TOKENS)
    blocks, tokens = JuDoc.find_md_ocblocks(tokens)
    lxdefs, tokens, braces, blocks = JuDoc.find_lxdefs(tokens, blocks)
    lxcoms, _ = JuDoc.find_md_lxcoms(tokens, lxdefs, braces)

    @test lxdefs[1].name == "\\com" && lxdefs[1].narg == 0 &&  lxdefs[1].def == "blah"
    @test lxdefs[2].name == "\\comb" && lxdefs[2].narg == 1 && lxdefs[2].def == "\\mathrm{#1}"
    @test lxdefs[3].name == "\\comc" && lxdefs[3].narg == 2 && lxdefs[3].def == "part1:#1 and part2:#2"
    @test blocks[1].name == :ESCAPE
    @test blocks[1].ss == "~~~\nescape B1\n~~~"
end


@testset "Merge-blocks" begin
    st = raw"""
        @def title = "Convex Optimisation I"
        \newcommand{\com}[1]{⭒!#1⭒}
        \com{A}
        <!-- comment -->
        then some
        ## blah <!-- ✅ 19/9/999 -->
        end \com{B}.
        """ * JuDoc.EOS

    tokens = JuDoc.find_tokens(st, JuDoc.MD_TOKENS, JuDoc.MD_1C_TOKENS)
    blocks, tokens = JuDoc.find_md_ocblocks(tokens)
    lxdefs, tokens, braces, blocks = JuDoc.find_lxdefs(tokens, blocks)
    lxcoms, _ = JuDoc.find_md_lxcoms(tokens, lxdefs, braces)

    @test blocks[1].name == :COMMENT
    @test JuDoc.content(blocks[1]) == " comment "
    @test blocks[2].name == :COMMENT
    @test JuDoc.content(blocks[2]) == " ✅ 19/9/999 "
    @test blocks[3].name == :MD_DEF
    @test JuDoc.content(blocks[3]) == " title = \"Convex Optimisation I\""

    @test lxcoms[1].ss == "\\com{A}"
    @test lxcoms[2].ss == "\\com{B}"

    b2i = JuDoc.merge_blocks(lxcoms, blocks)

    @test b2i[1].ss == "@def title = \"Convex Optimisation I\"\n"
    @test b2i[2].ss == "\\com{A}"
    @test b2i[3].ss == "<!-- comment -->"
    @test b2i[4].ss == "<!-- ✅ 19/9/999 -->"
    @test b2i[5].ss == "\\com{B}"
end
