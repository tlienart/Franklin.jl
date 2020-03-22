tok  = s -> F.find_tokens(s, F.MD_TOKENS, F.MD_1C_TOKENS)
vfn  = s -> (t = tok(s); F.validate_footnotes!(t); t)
vh   = s -> (t = vfn(s); F.validate_headers!(t); t)
fib  = s -> (t = vh(s); F.find_indented_blocks!(t, s); t)
fib2 = s -> (t = fib(s); F.filter_lr_indent!(t, s); t)
mdb  = s -> (t = tok(s); F.merge_double_braces!(t); t)

islr(t) = t.name == :LINE_RETURN && t.ss == "\n"
istok(t, n, s) = t.name == n && t.ss == s
isind(t) = t.name == :LR_INDENT && t.ss == "\n    "

##
## FIND_TOKENS
##

@testset "P:1:find-tok" begin
    t = raw"""
    @def v = 5
    @@da
        @@db
        @@
    @@
    $A$ and \[B\] and \com{hello} etc
    """ |> tok
    @test istok(t[1], :MD_DEF_OPEN, "@def")
    @test islr(t[2])
    @test istok(t[3], :DIV_OPEN,    "@@da")
    @test islr(t[4])
    @test istok(t[5], :DIV_OPEN, "@@db")
    @test islr(t[6])
    @test istok(t[7], :DIV_CLOSE, "@@")
    @test islr(t[8])
    @test istok(t[9], :DIV_CLOSE, "@@")
    @test islr(t[10])
    @test istok(t[11], :MATH_A, "\$")
    @test istok(t[12], :MATH_A, "\$")
    @test istok(t[13], :MATH_C_OPEN, "\\[")
    @test istok(t[14], :MATH_C_CLOSE, "\\]")
    @test istok(t[15], :LX_COMMAND, "\\com")
    @test istok(t[16], :LXB_OPEN, "{")
    @test istok(t[17], :LXB_CLOSE, "}")
    @test islr(t[18])
    @test istok(t[19], :EOS, "\n")

    # complement div with `-` or `_`
    t = raw"""A @@d-a B@@ C""" |> tok
    @test istok(t[1], :DIV_OPEN, "@@d-a")
    t = raw"""A @@d-1 B@@ C""" |> tok
    @test istok(t[1], :DIV_OPEN, "@@d-1")
end

@testset "P:1:ctok" begin
    # check that tokens at EOS close properly
    # NOTE: this was avoided before by the addition of a special char
    # to denote the end of the string but we don't do that anymore.
    # see `isexactly` and `find_tokens` in the fixed pattern case.
    t = "@@d ... @@" |> tok
    @test istok(t[1], :DIV_OPEN, "@@d")
    @test istok(t[2], :DIV_CLOSE, "@@")
    @test istok(t[3], :EOS, "@")
    t = "``` ... ```" |> tok
    @test istok(t[1], :CODE_TRIPLE, "```")
    @test istok(t[2], :CODE_TRIPLE, "```")
    @test istok(t[3], :EOS, "`")
    t = "<!--...-->" |> tok
    @test istok(t[1], :COMMENT_OPEN, "<!--")
    @test istok(t[2], :COMMENT_CLOSE, "-->")
    t = "~~~...~~~" |> tok
    @test istok(t[1], :ESCAPE, "~~~")
    @test istok(t[2], :ESCAPE, "~~~")
    t = "b `j`" |> tok
    @test istok(t[1], :CODE_SINGLE, "`")
    @test istok(t[2], :CODE_SINGLE, "`")
    @test istok(t[3], :EOS, "`")
end

##
## VALIDATE_FOOTNOTE!
##

@testset "P:1:val-fn" begin
    t = raw"""
    A [^B] and
    [^B]: etc
    """ |> vfn
    @test istok(t[1], :FOOTNOTE_REF, "[^B]")
    @test islr(t[2])
    @test istok(t[3], :FOOTNOTE_DEF, "[^B]:")
end

##
## VALIDATE_HEADERS!
##

@testset "P:1:val-hd" begin
    t = raw"""
    # A
    ## B
    and # C
    """ |> vh
    @test istok(t[1], :H1_OPEN, "#")
    @test islr(t[2])
    @test istok(t[3], :H2_OPEN, "##")
    @test islr(t[4])
    @test islr(t[5])
    @test istok(t[6], :EOS, "\n")
end

##
## FIND_INDENTED_BLOCKS!
##

@testset "P:1:fib" begin
    s = raw"""
    A

        B1
        B2
        B3
    C
    @@da
        @@db
            E
        @@
    @@
    E
        F
    G
    """
    t = s |> fib
    @test islr(t[1])
    @test isind(t[2]) && t[2].lno == 3
    @test isind(t[3]) && t[3].lno == 4
    @test isind(t[4]) && t[4].lno == 5 # B3
    @test islr(t[5])
    @test islr(t[6])
    @test istok(t[7], :DIV_OPEN, "@@da")
    @test isind(t[8]) && t[8].lno == 8
    @test istok(t[9], :DIV_OPEN, "@@db")
    @test isind(t[10]) && t[10].lno == 9  # in front of E
    @test isind(t[11]) && t[11].lno == 10 # in front of @@
    @test istok(t[12], :DIV_CLOSE, "@@")
    @test islr(t[13])
    @test istok(t[14], :DIV_CLOSE, "@@")
    @test islr(t[15])
    @test isind(t[16]) && t[16].lno == 13 # F
    @test islr(t[17])
    @test islr(t[18])
    @test istok(t[19], :EOS, "\n")

    t = s |> fib2
    @test length(t) == 19

    @test isind.([t[2], t[3], t[4]]) |> all
    @test islr.([t[8], t[10], t[11], t[16]]) |> all
end

##
## MERGE_DOUBLE_BRACES!
##

@testset "P:1:mdb" begin
    s = raw"""
        A { B } C {{ D }} E {F} G {{ H }}.
        """
    t = s |> mdb
    @test t[1].name == :LXB_OPEN
    @test t[2].name == :LXB_CLOSE
    @test t[3].name == :DB_OPEN
    @test t[4].name == :DB_CLOSE
    @test t[5].name == :LXB_OPEN
    @test t[6].name == :LXB_CLOSE
    @test t[7].name == :DB_OPEN
    @test t[8].name == :DB_CLOSE
    @test t[9].name == :LINE_RETURN
    @test t[10].name == :EOS

    s = raw"""{} {{}}"""
    t = s |> mdb
    @test t[1].name == :LXB_OPEN
    @test t[2].name == :LXB_CLOSE
    @test t[3].name == :DB_OPEN
    @test t[4].name == :DB_CLOSE
end
