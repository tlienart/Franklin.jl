@testset "Parser 1" begin
    stest = raw"""
        <!-- a comment \blah \$ on ```
        several lines --> blah \{ \com{blih} and *this*
        @def var = 5
        but then @@dname and so \bleh @@ but then
        $math targ1$ and $$math \$ targ2$$ blah
        ```julia
        x = 5
        println(x)
        ```
        and here `x` takes the value `5`.
        ~~~
        escaped block { etc
        ~~~
        Now let's test the maths $\sin(x)+1$ and $$\exp(i\pi)-1$$ and
        \begin{eqnarray} some stuff &=& \sqrt{blah} \end{eqnarray}
        and then also \[ 1+1 = 2 \] and maybe
        \begin{align} 1-1 &= 0 \end{align}
        tada.
        """ * "⌑"
    tokens = JuDoc.find_tokens(stest, JuDoc.MD_TOKENS, JuDoc.MD_1C_TOKENS)
    activetokens = [τ.name ∉ [:INACTIVE, :LINE_RETURN] for τ ∈ tokens]
    tester = [
            (JuDoc.Token(:COMMENT_OPEN, 1, 4), true),
            (JuDoc.Token(:LX_COMMAND, 16, 20), true),
            (JuDoc.Token(:INACTIVE, 22, 23), false),
            (JuDoc.Token(:CODE, 28, 30), true),
            (JuDoc.Token(:LINE_RETURN, 31, 31), false),
            (JuDoc.Token(:COMMENT_CLOSE, 46, 48), true),
            (JuDoc.Token(:INACTIVE, 55, 56), false),
            (JuDoc.Token(:LX_COMMAND, 58, 61), true),
            (JuDoc.Token(:LX_BRACE_OPEN, 62, 62), true),
            (JuDoc.Token(:LX_BRACE_CLOSE, 67, 67), true),
            (JuDoc.Token(:LINE_RETURN, 79, 79), false),
            (JuDoc.Token(:MD_DEF_OPEN, 80, 83), true),
            (JuDoc.Token(:LINE_RETURN, 92, 92), false),
            (JuDoc.Token(:DIV_OPEN, 102, 108), true),
            (JuDoc.Token(:LX_COMMAND, 117, 121), true),
            (JuDoc.Token(:DIV_CLOSE, 123, 124), true),
            (JuDoc.Token(:LINE_RETURN, 134, 134), false),
            (JuDoc.Token(:MATH_A, 135, 135), true),
            (JuDoc.Token(:MATH_A, 146, 146), true),
            (JuDoc.Token(:MATH_B, 152, 153), true),
            (JuDoc.Token(:INACTIVE, 159, 160), false),
            (JuDoc.Token(:MATH_B, 167, 168), true),
            (JuDoc.Token(:LINE_RETURN, 174, 174), false),
            (JuDoc.Token(:CODE_L, 175, 182), true),
            (JuDoc.Token(:LINE_RETURN, 183, 183), false),
            (JuDoc.Token(:LINE_RETURN, 189, 189), false),
            (JuDoc.Token(:LINE_RETURN, 200, 200), false),
            (JuDoc.Token(:CODE, 201, 203), true),
            (JuDoc.Token(:LINE_RETURN, 204, 204), false),
            (JuDoc.Token(:CODE_SINGLE, 214, 214), true),
            (JuDoc.Token(:CODE_SINGLE, 216, 216), true),
            (JuDoc.Token(:CODE_SINGLE, 234, 234), true),
            (JuDoc.Token(:CODE_SINGLE, 236, 236), true),
            (JuDoc.Token(:LINE_RETURN, 238, 238), false),
            (JuDoc.Token(:ESCAPE, 239, 241), true),
            (JuDoc.Token(:LINE_RETURN, 242, 242), false),
            (JuDoc.Token(:LX_BRACE_OPEN, 257, 257), true),
            (JuDoc.Token(:LINE_RETURN, 262, 262), false),
            (JuDoc.Token(:ESCAPE, 263, 265), true),
            (JuDoc.Token(:LINE_RETURN, 266, 266), false),
            (JuDoc.Token(:MATH_A, 292, 292), true),
            (JuDoc.Token(:LX_COMMAND, 293, 296), true),
            (JuDoc.Token(:MATH_A, 302, 302), true),
            (JuDoc.Token(:MATH_B, 308, 309), true),
            (JuDoc.Token(:LX_COMMAND, 310, 313), true),
            (JuDoc.Token(:LX_COMMAND, 316, 318), true),
            (JuDoc.Token(:MATH_B, 322, 323), true),
            (JuDoc.Token(:LINE_RETURN, 328, 328), false),
            (JuDoc.Token(:MATH_EQA_OPEN, 329, 344), true),
            (JuDoc.Token(:LX_COMMAND, 361, 365), true),
            (JuDoc.Token(:LX_BRACE_OPEN, 366, 366), true),
            (JuDoc.Token(:LX_BRACE_CLOSE, 371, 371), true),
            (JuDoc.Token(:MATH_EQA_CLOSE, 373, 386), true),
            (JuDoc.Token(:LINE_RETURN, 387, 387), false),
            (JuDoc.Token(:MATH_C_OPEN, 402, 403), true),
            (JuDoc.Token(:MATH_C_CLOSE, 413, 414), true),
            (JuDoc.Token(:LINE_RETURN, 425, 425), false),
            (JuDoc.Token(:MATH_ALIGN_OPEN, 426, 438), true),
            (JuDoc.Token(:MATH_ALIGN_CLOSE, 449, 459), true),
            (JuDoc.Token(:LINE_RETURN, 460, 460), false),
            (JuDoc.Token(:LINE_RETURN, 466, 466), false)]
    for (τ, ϕ, ρ) ∈ zip(tokens, activetokens, tester)
        @test τ.name == ρ[1].name && τ.from == ρ[1].from && τ.to == ρ[1].to
        @test ϕ == ρ[2]
    end
    xblocks, tokens = JuDoc.find_md_xblocks(tokens)
    tester = [
            JuDoc.Block(:COMMENT, 1, 48),
            JuDoc.Block(:MD_DEF, 80, 92),
            JuDoc.Block(:MATH_A, 135, 146),
            JuDoc.Block(:MATH_B, 152, 168),
            JuDoc.Block(:CODE, 175, 203),
            JuDoc.Block(:CODE_SINGLE, 214, 216),
            JuDoc.Block(:CODE_SINGLE, 234, 236),
            JuDoc.Block(:ESCAPE, 239, 265),
            JuDoc.Block(:MATH_A, 292, 302),
            JuDoc.Block(:MATH_B, 308, 323),
            JuDoc.Block(:MATH_EQA, 329, 386),
            JuDoc.Block(:MATH_C, 402, 414),
            JuDoc.Block(:MATH_ALIGN, 426, 459)]
    for (β, ρ) ∈ zip(xblocks, tester)
        @test β.name == ρ.name && β.from == ρ.from && β.to == ρ.to
    end
    bblocks, tokens = JuDoc.find_md_bblocks(tokens)
    @test stest[bblocks[1].from:bblocks[1].to] == "{blih}"
    @test stest[bblocks[2].from:bblocks[2].to] == "{blah}"
end


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

    # now we can kill all the line returns (md defs have been found)
    tokens = filter(τ -> τ.name != :LINE_RETURN, tokens)

    # figure out where the remaining blocks are.
    allblocks = JuDoc.get_md_allblocks(xblocks, lxdefs, lastindex(st) - 1)

    # filter out trivial blocks
    allblocks = filter(β -> (st[β.from:β.to] != "\n"), allblocks)

    @test allblocks[1].name == :REMAIN
    @test allblocks[2].name == :ESCAPE
    @test allblocks[3].name == :REMAIN
    @test allblocks[4].name == :CODE
end


# TODO TODO
# finish test, make sure JuDoc.merge_xblocks_lxcoms works.
@testset "Find LxComs" begin
    st = raw"""
        \newcommand{\com}{HH}
        \newcommand{\comb}[1]{HH#1HH}
        Blah \com and \comb{blah} etc
        ```julia
        f(x) = x^2
        ```
        etc \comb{blah}
        """ * JuDoc.EOS

    # Tokenization and Markdown conversion
    tokens = JuDoc.find_tokens(st, JuDoc.MD_TOKENS, JuDoc.MD_1C_TOKENS)
    tokens = JuDoc.deactivate_xblocks(tokens, JuDoc.MD_EXTRACT)
    bblocks, tokens = JuDoc.find_md_bblocks(tokens)
    lxdefs, tokens = JuDoc.find_md_lxdefs(st, tokens, bblocks)
    lxcoms, tokens = JuDoc.find_md_lxcoms(st, tokens, lxdefs, bblocks)

    @test lxcoms[1].name == :LX_COM_NOARG
    @test st[lxcoms[1].from:lxcoms[1].to] == "\\com"
    @test lxcoms[2].name == :LX_COM_WARGS
    @test st[lxcoms[2].from:lxcoms[2].to] == "\\comb{blah}"


end
