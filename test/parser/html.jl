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


@testset "Qual hblocks" begin
    st = raw"""
        Some text then {{ fill v1 }} and
        {{ if b1 }}
        show stuff here {{ fill v2 }}
        {{ else }}
        show other stuff
        {{ end }}
        """
    tokens = JuDoc.find_tokens(st, JuDoc.HTML_TOKENS, JuDoc.HTML_1C_TOKENS)
    hblocks, tokens = JuDoc.find_html_hblocks(tokens)
    qblocks = JuDoc.qualify_html_hblocks(hblocks, st)
    @test qblocks[1].fname == "fill"
    @test qblocks[1].params == ["v1"]
    @test qblocks[2].vname == "b1"
    @test qblocks[3].fname == "fill"
    @test qblocks[3].params == ["v2"]
    @test typeof(qblocks[4]) == JuDoc.HElse
    @test typeof(qblocks[5]) == JuDoc.HEnd
end


@testset "Cond block" begin
    st = raw"""
        Some text then {{ fill v1 }} and
        {{ if b1 }}
        show stuff here {{ fill v2 }}
        {{ else if b2 }}
        other stuff
        {{ else }}
        show other stuff
        {{ end }}
        final text
        """
    tokens = JuDoc.find_tokens(st, JuDoc.HTML_TOKENS, JuDoc.HTML_1C_TOKENS)
    hblocks, tokens = JuDoc.find_html_hblocks(tokens)
    qblocks = JuDoc.qualify_html_hblocks(hblocks, st)

    cblocks = JuDoc.find_html_cblocks(qblocks)

    @test cblocks[1].vcond1 == "b1"
    @test cblocks[1].vconds == ["b2"]
    @test st[cblocks[1].dofrom[1]:cblocks[1].doto[1]] ==
        "\nshow stuff here {{ fill v2 }}\n"
    @test st[cblocks[1].dofrom[2]:cblocks[1].doto[2]] ==
        "\nother stuff\n"
    @test st[cblocks[1].dofrom[3]:cblocks[1].doto[3]] ==
        "\nshow other stuff\n"

    allblocks = JuDoc.get_html_allblocks(cblocks, endof(st))

end

# allblocks = JuDoc.get_html_allblocks(hblocks, endof(st))
