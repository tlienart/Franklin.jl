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

@testset "h-for3" begin
    F.def_LOCAL_VARS!()
    s = """
        @def iter = (("a", 1), ("b", 2), ("c", 3))
        """ |> fd2html_td
    h = raw"""
        ABC
        {{for (n, v) in iter}}
            name:{{fill n}}
            value:{{fill v}}
        {{end}}
        """ |> F.convert_html
    @test isapproxstr(h, """
        ABC
        name:a
        value:1
        name:b
        value:2
        name:c
        value:3
        """)

    s = """
        @def iter2 = ("a"=>10, "b"=>7, "c"=>3)
        """ |> fd2html_td
    h = raw"""
        ABC
        {{for (n, v) in iter2}}
            name:{{fill n}}
            value:{{fill v}}
        {{end}}
        """ |> F.convert_html
    @test isapproxstr(h, """
        ABC
        name:a
        value:10
        name:b
        value:7
        name:c
        value:3
        """)
end


# read from file, see FranklinFAQ-001
@testset "for-file" begin
    gotd()
    write("members.csv", """
    name,github
    Eric Mill,konklone
    Parker Moore,parkr
    Liu Fengyun,liufengyun
    """)
    s = """
        @def members = eachrow(readdlm("members.csv", ',', skipstart=1))
        ~~~
        <ul>
        {{for (name, alias) in members}}
          <li>
            <a href="https://github.com/{{alias}}">{{name}}</a>
          </li>
        {{end}}
        </ul>
        ~~~
        """ |> fd2html
    @test isapproxstr(s, """
                <ul>
                  <li>
                    <a href="https://github.com/konklone">Eric Mill</a>
                  </li>
                  <li>
                    <a href="https://github.com/parkr">Parker Moore</a>
                  </li>
                  <li>
                    <a href="https://github.com/liufengyun">Liu Fengyun</a>
                  </li>
                </ul>""")
end
