@testset "Get hblocks" begin
    st = raw"""
        Some text then {{ a block }} maybe another
        one with nesting {{ blah {{ ... }} }}.
        """
    tokens = JuDoc.find_tokens(st, JuDoc.HTML_TOKENS, JuDoc.HTML_1C_TOKENS)
    hblocks, tokens = JuDoc.find_html_hblocks(tokens)
    allblocks = JuDoc.get_html_allblocks(hblocks, endof(st))

    @test st[allblocks[1].from:allblocks[1].to] == "Some text then "
    @test st[allblocks[2].from:allblocks[2].to] == "{{ a block }}"
    @test st[allblocks[3].from:allblocks[3].to] == " maybe another\none with nesting "
    @test st[allblocks[4].from:allblocks[4].to] == "{{ blah {{ ... }} }}"
    @test st[allblocks[5].from:allblocks[5].to] == ".\n"
end
