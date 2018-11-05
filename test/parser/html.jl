@testset "Find hblocks" begin
    st = raw"""
        Some text then {{ fill v1 }} and
        {{ if b1 }}
        show stuff here {{ fill v2 }}
        {{ else }}
        show other stuff
        {{ end }}"""

    tokens = JuDoc.find_tokens(st, JuDoc.HTML_TOKENS, JuDoc.HTML_1C_TOKENS)
    hblocks, tokens = JuDoc.find_all_ocblocks(tokens, J.HTML_OCB)
    @test hblocks[1].ss == "{{ fill v1 }}"
    @test hblocks[2].ss == "{{ if b1 }}"
    @test hblocks[3].ss == "{{ fill v2 }}"
    @test hblocks[4].ss == "{{ else }}"
    @test hblocks[5].ss == "{{ end }}"
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
    hblocks, tokens = JuDoc.find_all_ocblocks(tokens, J.HTML_OCB)
    qblocks = JuDoc.qualify_html_hblocks(hblocks)

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
        {{ elseif b2 }}
        other stuff
        {{ else }}
        show other stuff
        {{ end }}
        final text
        """

    tokens = JuDoc.find_tokens(st, JuDoc.HTML_TOKENS, JuDoc.HTML_1C_TOKENS)
    hblocks, tokens = JuDoc.find_all_ocblocks(tokens, J.HTML_OCB)
    qblocks = JuDoc.qualify_html_hblocks(hblocks)
    cblocks, qblocks = JuDoc.find_html_cblocks(qblocks)

    @test cblocks[1].init_cond == "b1"
    @test cblocks[1].sec_conds == ["b2"]
    @test cblocks[1].actions[1] == "\nshow stuff here {{ fill v2 }}\n"
    @test cblocks[1].actions[2] == "\nother stuff\n"
    @test cblocks[1].actions[3] == "\nshow other stuff\n"
end


@testset "Merge blocks" begin
    st = raw"""
        Some text then {{ fill v1 }} and
        {{ if b1 }}
        show stuff here {{ fill v2 }}
        {{ elseif b2 }}
        other stuff
        {{ else }}
        show other stuff
        {{ end }}
        final text
        """

    tokens = JuDoc.find_tokens(st, JuDoc.HTML_TOKENS, JuDoc.HTML_1C_TOKENS)
    hblocks, tokens = JuDoc.find_all_ocblocks(tokens, J.HTML_OCB)
    qblocks = JuDoc.qualify_html_hblocks(hblocks)
    cblocks, qblocks = JuDoc.find_html_cblocks(qblocks)
    cdblocks, qblocks = JuDoc.find_html_cdblocks(qblocks)
    hblocks = JuDoc.merge_blocks(qblocks, cblocks, cdblocks)

    @test hblocks[1].ss == "{{ fill v1 }}"
    @test hblocks[2].ss == "{{ if b1 }}\nshow stuff here {{ fill v2 }}\n{{ elseif b2 }}\nother stuff\n{{ else }}\nshow other stuff\n{{ end }}"
end
