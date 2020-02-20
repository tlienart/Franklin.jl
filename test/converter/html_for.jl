@testset "h-for" begin
    F.def_LOCAL_VARS!()
    s = """
        @def list = [1,2,3]
        """ |> fd2html_td
    hs = raw"""
        ABC
        {{for x in list}}
          {{fill x}}
        {{end}}
        """
    tokens = F.find_tokens(hs, F.HTML_TOKENS, F.HTML_1C_TOKENS)
    hblocks, tokens = F.find_all_ocblocks(tokens, F.HTML_OCB)
    qblocks = F.qualify_html_hblocks(hblocks)
    @test qblocks[1] isa F.HFor
    @test qblocks[1].vname == "x"
    @test qblocks[1].iname == "list"
    @test qblocks[2] isa F.HFun
    @test qblocks[3] isa F.HEnd

    content, head, i = F.process_html_for(hs, qblocks, 1)
    @test isapproxstr(content, "1 2 3")
end

@testset "h-for2" begin
    F.def_LOCAL_VARS!()
    s = """
        @def list = ["path/to/badge1.png", "path/to/badge2.png"]
        """ |> fd2html_td
    h = raw"""
        ABC
        {{for x in list}}
            {{fill x}}
        {{end}}
        """ |> F.convert_html
    @test isapproxstr(h, """
        ABC
        path/to/badge1.png
        path/to/badge2.png
        """)
end
