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
    cblocks, qblocks = JuDoc.find_html_cblocks(qblocks)

    @test cblocks[1].vcond1 == "b1"
    @test cblocks[1].vconds == ["b2"]
    @test st[cblocks[1].dofrom[1]:cblocks[1].doto[1]] ==
        "\nshow stuff here {{ fill v2 }}\n"
    @test st[cblocks[1].dofrom[2]:cblocks[1].doto[2]] ==
        "\nother stuff\n"
    @test st[cblocks[1].dofrom[3]:cblocks[1].doto[3]] ==
        "\nshow other stuff\n"

    allblocks = JuDoc.get_html_allblocks(qblocks, cblocks, lastindex(st))
    @test allblocks[1].name == :REMAIN
    @test typeof(allblocks[2]) == JuDoc.HFun
    @test allblocks[2].fname == "fill"
    @test typeof(allblocks[4]) == JuDoc.HCond
end


@testset "Cblock+h-fill" begin
    allvars = Dict{String, Pair{Any, Tuple}}(
        "v1" => "INPUT1" => (String,),
        "b1" => false => (Bool,),
        "b2" => true  => (Bool,))

    hs = raw"""
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
    @test JuDoc.convert_html(hs, allvars) == "Some text then INPUT1 and\n\nother stuff\n\nfinal text\n"
end


@testset "h-insert" begin
    # NOTE: the test/jd_paths.jl must have been run before
    temp_rnd = joinpath(JuDoc.JD_PATHS[:in_html], "temp.rnd")
    write(temp_rnd, "some random text to insert")
    hs = raw"""
        Trying to insert: {{ insert temp.rnd }} and see.
        """
    allvars = Dict()
    @test JuDoc.convert_html(hs, allvars) == "Trying to insert: some random text to insert and see.\n"
end
