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

    tokens = JuDoc.find_tokens(hs, JuDoc.HTML_TOKENS, JuDoc.HTML_1C_TOKENS)
    hblocks, tokens = JuDoc.find_all_ocblocks(tokens, J.HTML_OCB)
    qblocks = JuDoc.qualify_html_hblocks(hblocks)
    cblocks, qblocks = JuDoc.find_html_cblocks(qblocks)
    cdblocks, qblocks = JuDoc.find_html_cdblocks(qblocks)
    hblocks = JuDoc.merge_blocks(qblocks, cblocks, cdblocks)
    convhbs = [JuDoc.convert_hblock(hb, allvars) for hb ∈ hblocks]
    @test convhbs[1] == "INPUT1"
    @test convhbs[2] == "\nother stuff\n"
    @test JuDoc.convert_html(hs, allvars) == "Some text then INPUT1 and\n\nother stuff\n\nfinal text\n"
end


@testset "h-insert" begin
    # Julia 0.7 complains if there's no global here.
    global temp_rnd = joinpath(JuDoc.JD_PATHS[:in_html], "temp.rnd")
    write(temp_rnd, "some random text to insert")
    hs = raw"""
        Trying to insert: {{ insert temp.rnd }} and see.
        """
    allvars = Dict()
    @test JuDoc.convert_html(hs, allvars) == "Trying to insert: some random text to insert and see.\n"
end


@testset "cond-insert" begin
    allvars = Dict{String, Pair{Any, Tuple}}(
        "author" => "Stefan Zweig" => (String, Nothing),
        "date_format" => "U dd, yyyy" => (String,),
        "isnotes" => true => (Bool,))
    hs = "foot {{if isnotes}} {{fill author}}{{end}}"
    rhs = JuDoc.convert_html(hs, allvars)
    @test rhs == "foot  Stefan Zweig"
end


@testset "cond-insert 2" begin
    allvars = Dict{String, Pair{Any, Tuple}}(
        "author" => "Stefan Zweig" => (String, Nothing),
        "date_format" => "U dd, yyyy" => (String,),
        "isnotes" => true => (Bool,))
    hs = "foot {{ifdef author}} {{fill author}}{{end}}"
    rhs = JuDoc.convert_html(hs, allvars)
    @test rhs == "foot  Stefan Zweig"
end

@testset "escape-coms" begin
    allvars = Dict{String, Pair{Any, Tuple}}(
        "author" => "Stefan Zweig" => (String, Nothing),
        "date_format" => "U dd, yyyy" => (String,),
        "isnotes" => true => (Bool,))
    hs = "foot <!-- {{ fill blahblah }} {{ if v1 }} --> {{ifdef author}} {{fill author}}{{end}}"
    rhs = JuDoc.convert_html(hs, allvars)
    @test rhs == "foot <!-- {{ fill blahblah }} {{ if v1 }} -->  Stefan Zweig"
end


@testset "Cblock+empty" begin # refers to #96
    allvars = Dict(
        "b1" => false => (Bool,),
        "b2" => true => (Bool,))

    jdc = x->JuDoc.convert_html(x, allvars)

    # flag b1 is false
    @test "{{if b1}} blah {{ else }} blih {{ end }}" |> jdc == " blih " # else
    @test "{{if b1}} {{ else }} blih {{ end }}" |> jdc == " blih "      # else

    # flag b2 is true
    @test "{{if b2}} blah {{ else }} blih {{ end }}" |> jdc == " blah " # if
    @test "{{if b2}} blah {{ else }} {{ end }}" |> jdc == " blah "      # if
    @test "{{if b2}} blah {{ end }}" |> jdc == " blah "                 # if

    @test "{{if b1}} blah {{ else }} {{ end }}" |> jdc == "" # else, empty
    @test "{{if b1}} {{ else }} {{ end }}" |> jdc == ""      # else, empty
    @test "{{if b1}} blah {{ end }}" |> jdc == ""            # else, empty
    @test "{{if b2}} {{ else }} {{ end }}" |> jdc == ""      # if, empty
    @test "{{if b2}} {{ else }} blih {{ end }}" |> jdc == "" # if, empty
end
