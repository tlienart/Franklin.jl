@testset "Latex1" begin
    st = raw"""
        text A1 \newcommand{\com}{blah}text A2 \com and
        ~~~
        escape B1
        ~~~
        \newcommand{\comb}[ 1]{\mathrm{#1}} text C1 $\comb{b}$ text C2
        """ * JuDoc.EOS
    tokens = JuDoc.find_tokens(st, JuDoc.MD_TOKENS, JuDoc.MD_1C_TOKENS)
    tokens = JuDoc.deactivate_xblocks(tokens, JuDoc.MD_EXTRACT)
    bblocks, tokens = JuDoc.find_md_bblocks(tokens)
    lxdefs, tokens = JuDoc.find_md_lxdefs(st, tokens, bblocks)
    xblocks, tokens = JuDoc.find_md_xblocks(tokens)
    tokens = filter(τ -> τ.name != :LINE_RETURN, tokens)
    allblocks = JuDoc.get_md_allblocks(xblocks, lxdefs, lastindex(st) - 1)
    allblocks = filter(β -> (st[β.from:β.to] != "\n"), allblocks)

    coms = filter(τ -> τ.name == :LX_COMMAND, tokens)
    # construct the string
    context = (st, coms, lxdefs, bblocks)
    v = [JuDoc.convert_md__procblock(β, context...) for β ∈ allblocks]

    @test v[1] == "text A1 "
    @test v[2] == "text A2 blah and\n"
    @test v[3] == "\nescape B1\n"
    @test v[4] == " text C1 "
    @test v[5] == "\\(\\mathrm{b}\\)"
    @test v[6] == " text C2\n"

    s = prod(v)
    @test s == "text A1 text A2 blah and\n\nescape B1\n text C1 \\(\\mathrm{b}\\) text C2\n"
end

@testset "Latex 2" begin
    st = raw"""a\newcommand{\eqa}[1]{\begin{eqnarray}#1\end{eqnarray}}b
        \eqa{\sin^2(x)+\cos^2(x) &=& 1}""" * JuDoc.EOS
    tokens = JuDoc.find_tokens(st, JuDoc.MD_TOKENS, JuDoc.MD_1C_TOKENS)
    tokens = JuDoc.deactivate_xblocks(tokens, JuDoc.MD_EXTRACT)
    bblocks, tokens = JuDoc.find_md_bblocks(tokens)
    lxdefs, tokens = JuDoc.find_md_lxdefs(st, tokens, bblocks)
    xblocks, tokens = JuDoc.find_md_xblocks(tokens)
    tokens = filter(τ -> τ.name != :LINE_RETURN, tokens)
    allblocks = JuDoc.get_md_allblocks(xblocks, lxdefs, lastindex(st) - 1)
    allblocks = filter(β -> (st[β.from:β.to] != "\n"), allblocks)
    coms = filter(τ -> τ.name == :LX_COMMAND, tokens)
    # only the third block will need latex processing
    β = allblocks[2]
    ltx = JuDoc.resolve_latex(st, β.from, β.to, false, coms, lxdefs, bblocks)

    @test ltx == "b\n\$\$\\begin{array}{c}\\sin^2(x)+\\cos^2(x) &=& 1\\end{array}\$\$"
end


@testset "Latex 3" begin
    st = raw"""
        \newcommand{ \coma }[ 1]{hello #1}
        \newcommand{ \comb} [2 ]{\coma{#1}, goodbye #1, #2!}
        Then \coma{auth1} and \comb{auth2}{voila} and \coma{auth3}
        """ * JuDoc.EOS
    tokens = JuDoc.find_tokens(st, JuDoc.MD_TOKENS, JuDoc.MD_1C_TOKENS)
    tokens = JuDoc.deactivate_xblocks(tokens, JuDoc.MD_EXTRACT)
    bblocks, tokens = JuDoc.find_md_bblocks(tokens)
    lxdefs, tokens = JuDoc.find_md_lxdefs(st, tokens, bblocks)
    xblocks, tokens = JuDoc.find_md_xblocks(tokens)
    tokens = filter(τ -> τ.name != :LINE_RETURN, tokens)
    allblocks = JuDoc.get_md_allblocks(xblocks, lxdefs, lastindex(st) - 1)
    allblocks = filter(β -> (st[β.from:β.to] != "\n"), allblocks)
    coms = filter(τ -> τ.name == :LX_COMMAND, tokens)
    # construct the string
    context = (st, coms, lxdefs, bblocks)
    s = prod(JuDoc.convert_md__procblock(β, context...) for β ∈ allblocks)
    @test s == "Then hello auth1 and hello auth2, goodbye auth2, voila&#33; and hello auth3\n"
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
    tokens = JuDoc.deactivate_xblocks(tokens, JuDoc.MD_EXTRACT)
    bblocks, tokens = JuDoc.find_md_bblocks(tokens)
    lxdefs, tokens = JuDoc.find_md_lxdefs(st, tokens, bblocks)
    xblocks, tokens = JuDoc.find_md_xblocks(tokens)
    tokens = filter(τ -> τ.name != :LINE_RETURN, tokens)
    allblocks = JuDoc.get_md_allblocks(xblocks, lxdefs, lastindex(st) - 1)
    allblocks = filter(β -> (st[β.from:β.to] != "\n"), allblocks)
    coms = filter(τ -> τ.name == :LX_COMMAND, tokens)
    # construct the string
    context = (st, coms, lxdefs, bblocks)
    s = prod(JuDoc.convert_md__procblock(β, context...) for β ∈ allblocks)
    @test s == "Then something like\n\$\$\\begin{array}{c} \\mathbb E\\left[f(X)\\right] \\in \\mathbb R &\\text{if}& f:\\mathbb R\\maptso\\mathbb R \\end{array}\$\$\n"
end
