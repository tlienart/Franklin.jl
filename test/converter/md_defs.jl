@testset "preprocess" begin
    s = """
        @def z = [1,2,3,
            4,5,6]
        """
    tokens = F.find_tokens(s, F.MD_TOKENS, F.MD_1C_TOKENS)
    F.find_indented_blocks!(tokens, s)

    @test tokens[1].name == :MD_DEF_OPEN
    @test tokens[2].name == :LR_INDENT
    @test tokens[3].name == :LINE_RETURN
    @test tokens[4].name == :EOS

    F.preprocess_candidate_mddefs!(tokens)

    @test tokens[1].name == :MD_DEF_OPEN
    @test tokens[2].name == :LINE_RETURN
    @test tokens[3].name == :EOS

    blocks, = F.find_all_ocblocks(tokens, F.MD_OCB_ALL)

    content = F.content.(blocks) .|> String
    @test isapproxstr(content[1], "z = [1,2,3,4,5,6]")

    s = """
        @def z1 = [1,2,3,
            4,5,6]
        @def z2 = 3
        @def z3 = [1,
            2,
                3]
        """
    tokens = F.find_tokens(s, F.MD_TOKENS, F.MD_1C_TOKENS)
    F.find_indented_blocks!(tokens, s)
    seqtok = (:MD_DEF_OPEN, :LR_INDENT, :LINE_RETURN,
              :MD_DEF_OPEN, :LINE_RETURN,
              :MD_DEF_OPEN, :LR_INDENT, :LR_INDENT, :LINE_RETURN,
              :EOS)
    for i in 1:length(tokens)
        @test tokens[i].name == seqtok[i]
    end

    F.preprocess_candidate_mddefs!(tokens)
    seqtok = (:MD_DEF_OPEN, :LINE_RETURN,
              :MD_DEF_OPEN, :LINE_RETURN,
              :MD_DEF_OPEN, :LINE_RETURN,
              :EOS)
    for i in 1:length(tokens)
        @test tokens[i].name == seqtok[i]
    end

    blocks, = F.find_all_ocblocks(tokens, F.MD_OCB_ALL)
    content = F.content.(blocks) .|> String
    @test isapproxstr(content[1], "z1=[1,2,3,4,5,6]")
    @test isapproxstr(content[2], "z2=3")
    @test isapproxstr(content[3], "z3=[1,2,3]")
end


@testset "mddefs1" begin
    F.def_LOCAL_VARS!()
    s = """
        @def x = 5
        """ |> fd2html_td
    @test F.locvar("x") == 5
    s = """
        @def x = "hello"; <!-- nothing -->
        """ |> fd2html_td
    @test F.locvar("x") == "hello"
    s = """
        @def x = "hello"
        @def y = pi
        """ |> fd2html_td
    @test F.locvar("x") == "hello"
    @test F.locvar("y") == pi
    s = """
        @def z = [1,2,3,
                  4,5,6]
        A
        """ |> fd2html_td
    @test F.locvar("z") == collect(1:6)
    s = """
        @def s = \"\"\"foo
            bar
            baz etc\"\"\"
        @def s2 = "nothing"
        """ |> fd2html_td
    @test isapproxstr(F.locvar("s"), "foo bar baz etc")
    @test isapproxstr(F.locvar("s2"), "nothing")
end
