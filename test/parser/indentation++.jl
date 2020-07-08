@testset "indentation" begin
    mds = """
        A
            B
            C
        D"""

    tokens = F.find_tokens(mds, F.MD_TOKENS, F.MD_1C_TOKENS)
    F.find_indented_blocks!(tokens, mds)
    toks = deepcopy(tokens)

    @test tokens[1].name == :LR_INDENT
    @test tokens[2].name == :LR_INDENT
    @test tokens[3].name == :LINE_RETURN

    ocp = F.OCProto(:CODE_BLOCK_IND, :LR_INDENT, (:LINE_RETURN,), false)

    blocks, tokens = F.find_ocblocks(tokens, ocp)

    @test blocks[1].name == :CODE_BLOCK_IND
    @test F.content(blocks[1]) == "B\n    C"

    blocks, tokens = F.find_all_ocblocks(toks, [ocp])

    @test blocks[1].name == :CODE_BLOCK_IND
    @test F.content(blocks[1]) == "B\n    C"

    mds = """
        @def indented_code = true
        A

            B
            C
        D"""
    steps = explore_md_steps(mds)
    toks = steps[:tokenization].tokens
    @test toks[4].name == toks[5].name == :LR_INDENT
    blk = steps[:ocblocks].blocks
    @test blk[2].name == :CODE_BLOCK_IND
    b2i = steps[:b2insert].b2insert
    @test b2i[2].name == :CODE_BLOCK_IND
    @test isapproxstr(mds |> fd2html_td, """
        <p>A</p>
        <pre><code class="language-julia">B
        C</code></pre>
        <p>D</p>
        """)
end

@testset "ind+lx" begin
    s = raw"""
        \newcommand{\julia}[1]{
            ```julia
            #1
            ```
        }
        Hello
        \julia{a=5
        x=3}
        """ |> fd2html_td
    @test isapproxstr(s, """
        <p>Hello <pre><code class="language-julia">a=5
        x=3</code></pre></p>
        """)
end
