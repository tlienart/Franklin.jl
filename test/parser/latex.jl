@testset "Latex1" begin
    st = raw"""
        text A1 \newcommand{\com}{blah}text A2 \com and
        ~~~
        escape B1
        ~~~
        \newcommand{\comb}[ 1]{\mathrm{#1}} text C1 $\comb{b}$ text C2
        """ * JuDoc.EOS
    tokens = JuDoc.find_tokens(st, JuDoc.MD_TOKENS, JuDoc.MD_1C_TOKENS)
    xblocks, tokens = JuDoc.find_md_xblocks(tokens)
    allblocks = JuDoc.get_allblocks(xblocks, endof(st) - 1)
    bblocks, tokens = JuDoc.find_md_bblocks(tokens)
    lxdefs, allblocks, tokens = JuDoc.find_md_lxdefs(st, tokens, allblocks, bblocks)
    lxdeflocs = [β.to for β ∈ allblocks if β.name == :NEWCOMMAND]
    coms = filter(τ -> τ.name == :LX_COMMAND, tokens)
    # construct the string
    context = (st, coms, lxdefs, lxdeflocs, bblocks)
    s = prod(JuDoc.convert_md__procblock(β, context...) for β ∈ allblocks)
    #= NOTE: the call to the base markdown parser chomps some whitespaces
    which is why some of the words are glued, it will not show in HTML though=#
    @test s == "text A1 text A2 blah and\nescape B1\ntext C1 \\(\\mathrm{b}\\)text C2"
end

@testset "Latex 2" begin
    st = raw"""a\newcommand{\eqa}[1]{\begin{eqnarray}#1\end{eqnarray}}b
        \eqa{\sin^2(x)+\cos^2(x) &=& 1}""" * JuDoc.EOS
    tokens = JuDoc.find_tokens(st, JuDoc.MD_TOKENS, JuDoc.MD_1C_TOKENS)
    xblocks, tokens = JuDoc.find_md_xblocks(tokens)
    allblocks = JuDoc.get_allblocks(xblocks, endof(st) - 1)
    bblocks, tokens = JuDoc.find_md_bblocks(tokens)
    lxdefs, allblocks, tokens = JuDoc.find_md_lxdefs(st, tokens, allblocks, bblocks)
    lxdeflocs = [β.to for β ∈ allblocks if β.name == :NEWCOMMAND]
    coms = filter(τ -> τ.name == :LX_COMMAND, tokens)

    @test allblocks[1].name == :REMAIN
    @test st[allblocks[1].from:allblocks[1].to] == "a"

    @test allblocks[2].name == :NEWCOMMAND
    @test st[allblocks[2].from:allblocks[2].to] == "\\newcommand{\\eqa}[1]{\\begin{eqnarray}#1\\end{eqnarray}}"

    @test allblocks[3].name == :REMAIN
    @test st[allblocks[3].from:allblocks[3].to] == "b\n\\eqa{\\sin^2(x)+\\cos^2(x) &=& 1}"

    @test lxdefs[1].name == "\\eqa"
    @test lxdefs[1].narg == 1
    @test lxdefs[1].def == "\\begin{eqnarray}#1\\end{eqnarray}"

    @test st[coms[1].from:coms[1].to] == "\\eqa"
    @test st[coms[2].from:coms[2].to] == "\\sin"
    @test st[coms[3].from:coms[3].to] == "\\cos"

    # only the third block will need latex processing
    β = allblocks[3]
    ltx = JuDoc.resolve_latex(st, β.from, β.to, false,
                            coms, lxdefs, lxdeflocs, bblocks)

    @test ltx == "b\n\$\$\\begin{array}{c}\\sin^2(x)+\\cos^2(x) &=& 1\\end{array}\$\$"
end


@testset "Latex 3" begin
    st = raw"""
        \newcommand{ \coma }[ 1]{hello #1}
        \newcommand{ \comb} [2 ]{\coma{#1}, goodbye #1, #2!}
        Then \coma{auth1} and \comb{auth2}{voila} and \coma{auth3}
        """ * JuDoc.EOS
    tokens = JuDoc.find_tokens(st, JuDoc.MD_TOKENS, JuDoc.MD_1C_TOKENS)
    xblocks, tokens = JuDoc.find_md_xblocks(tokens)
    allblocks = JuDoc.get_allblocks(xblocks, endof(st) - 1)
    bblocks, tokens = JuDoc.find_md_bblocks(tokens)
    lxdefs, allblocks, tokens = JuDoc.find_md_lxdefs(st, tokens, allblocks, bblocks)
    lxdeflocs = [β.to for β ∈ allblocks if β.name == :NEWCOMMAND]
    coms = filter(τ -> τ.name == :LX_COMMAND, tokens)
    # construct the string
    context = (st, coms, lxdefs, lxdeflocs, bblocks)
    s = prod(JuDoc.convert_md__procblock(β, context...) for β ∈ allblocks)
    @test s == "Then hello auth1 and hello auth2, goodbye auth2, voila&amp;#33; and hello auth3"
end


@testset "Latex 4" begin
    st = raw"""
        \newcommand{\E}[1]{\mathbb E\left[#1\right]}
        \newcommand{\eqa}[1]{\begin{eqnarray}#1\end{eqnarray}}
        \newcommand{\R}{\mathbb R}
        Then something like
        \eqa{ \E{f(X)} \in \R &\text{if}& f:\R\maptso\R }
        """ * JuDoc.EOS
    tokens = JuDoc.find_tokens(st, JuDoc.MD_TOKENS, JuDoc.MD_1C_TOKENS)
    xblocks, tokens = JuDoc.find_md_xblocks(tokens)
    allblocks = JuDoc.get_allblocks(xblocks, endof(st) - 1)
    bblocks, tokens = JuDoc.find_md_bblocks(tokens)
    lxdefs, allblocks, tokens = JuDoc.find_md_lxdefs(st, tokens, allblocks, bblocks)
    lxdeflocs = [β.to for β ∈ allblocks if β.name == :NEWCOMMAND]
    coms = filter(τ -> τ.name == :LX_COMMAND, tokens)
    # construct the string
    context = (st, coms, lxdefs, lxdeflocs, bblocks)
    s = prod(JuDoc.convert_md__procblock(β, context...) for β ∈ allblocks)
end
