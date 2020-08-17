tok  = s -> F.find_tokens(s, F.MD_TOKENS, F.MD_1C_TOKENS)
vfn  = s -> (t = tok(s); F.validate_footnotes!(t); t)
vh   = s -> (t = vfn(s); F.validate_start_of_line!(t, Franklin.MD_HEADER_OPEN); t)
fib  = s -> (t = vh(s); F.find_indented_blocks!(t, s); t)
fib2 = s -> (t = fib(s); F.filter_lr_indent!(t, s); t)

blk  = s -> (F.def_LOCAL_VARS!(); F.set_var!(F.LOCAL_VARS, "indented_code", true); F.find_all_ocblocks(fib2(s), F.MD_OCB_ALL))
blk2 = s -> ((b, t) = blk(s); F.merge_indented_blocks!(b, s); b)
blk3 = s -> (b = blk2(s); F.filter_indented_blocks!(b); b)

blk4 = s -> (b = blk3(s); F.validate_and_store_link_defs!(b); b)

isblk(b, n, s) = b.name == n && b.ss == s
cont(b) = F.content(b)

# Basics
@testset "P:2:blk" begin
    b, t = raw"""
    A <!--

        Hello
    -->
    Then ```julia 1+5``` and ~~~    ~~~.
    """ |> blk
    @test length(b) == 3
    @test isblk(b[1], :COMMENT, "<!--\n\n    Hello\n-->")
    @test isblk(b[2], :CODE_BLOCK_LANG, "```julia 1+5```")
    @test cont(b[2]) == " 1+5"
    @test isblk(b[3], :ESCAPE, "~~~    ~~~")
end

# with indentation
@testset "P:2:blk-ind" begin
    b, t = raw"""
    A

        B1
        B2
        B3
    @@d1
        B
    @@
    """ |> blk
    @test length(b) == 2
    @test isblk(b[1], :CODE_BLOCK_IND, "\n    B1\n    B2\n    B3\n")
    @test isblk(b[2], :DIV, "@@d1\n    B\n@@")

    b, t = raw"""
    @@d1
        @@d2
            B
        @@
    @@
    """ |> blk
    @test length(b) == 1
    @test isblk(b[1], :DIV, "@@d1\n    @@d2\n        B\n    @@\n@@")

    b, t = raw"""
    @@d1
        @@d2
            B
        @@
    @@
    """ |> blk
    @test length(b) == 1
    @test isblk(b[1], :DIV, "@@d1\n    @@d2\n        B\n    @@\n@@")
end

# with indentation and grouping and filtering
@testset "P:2:blk-indF" begin
    b = raw"""
    A

        B1
        B2

        B3
    C
    """ |> blk3
    @test isblk(b[1], :CODE_BLOCK_IND, "\n    B1\n    B2\n\n    B3\n")

    b = raw"""
    A

        B
        C
            D
        E

    F

        G



        H
    """ |> blk3
    @test length(b) == 2
    @test isblk(b[1], :CODE_BLOCK_IND, "\n    B\n    C\n        D\n    E\n")
    @test isblk(b[2], :CODE_BLOCK_IND, "\n    G\n\n\n\n    H\n")

    b = raw"""
    @@d1

        A
        B
        C
    @@
    """ |> blk3
    @test length(b) == 1
    @test isblk(b[1], :DIV, "@@d1\n\n    A\n    B\n    C\n@@")

    b = raw"""
    @@d1
        @@d2
            @@d3
                B
            @@
        @@
    @@
    """ |> blk3
    @test b[1].name == :DIV
end

@testset "More ind" begin
    b = "A\n\n\tB1\n\tB2\n\n\tB3\nC" |> blk3
    @test isblk(b[1], :CODE_BLOCK_IND, "\n\tB1\n\tB2\n\n\tB3\n")
end

@testset "P:2:blk-{}" begin
    b = "{ABC}" |> blk3
    @test F.content(b[1]) == "ABC"
    b = "\\begin{eqnarray} \\sin^2(x)+\\cos^2(x) &=& 1\\end{eqnarray}" |> blk3
    @test cont(b[1]) == " \\sin^2(x)+\\cos^2(x) &=& 1"
    b = raw"""
    a\newcommand{\eqa}[1]{\begin{eqnarray}#1\end{eqnarray}}b@@d .@@
    \eqa{\sin^2(x)+\cos^2(x) &=& 1}
    """ |> blk3
    @test isblk(b[1], :LXB, raw"{\eqa}")
    @test isblk(b[2], :LXB, raw"{\begin{eqnarray}#1\end{eqnarray}}")
    @test isblk(b[3], :LXB, raw"{\sin^2(x)+\cos^2(x) &=& 1}")
end

# links
@testset "P:2:blk-[]" begin
    b = """
    A [A] B.
    [A]: http://example.com""" |> blk4
    @test length(b) == 1
    @test isblk(b[1], :LINK_DEF, "[A]: http://example.com")
    b = """
    A [A][B] C.
    [B]: http://example.com""" |> blk4
    @test isblk(b[1], :LINK_DEF, "[B]: http://example.com")
    b = """
    A [`B`] C
    [`B`]: http://example.com""" |> blk4
    @test length(b) == 2
    @test isblk(b[1], :CODE_INLINE, "`B`")
    @test isblk(b[2], :LINK_DEF,    "[`B`]: http://example.com")
end
