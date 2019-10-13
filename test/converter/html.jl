@testset "Cblock+h-fill" begin
    allvars = J.PageVars(
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
    @test J.convert_html(hs, allvars) == "Some text then INPUT1 and\n\nother stuff\n\nfinal text\n"

    hs = raw"""
        abc {{isdef no}}yada{{end}} def
        """
    @test J.convert_html(hs, allvars) == "abc  def\n"

    hs = raw"""abc {{ fill nope }} ... """
    @test (@test_logs (:warn, "I found a '{{fill nope}}' but I do not know the variable 'nope'. Ignoring.") J.convert_html(hs, allvars))  == "abc  ... "

    hs = raw"""unknown fun {{ unknown fun }} and see."""
    @test (@test_logs (:warn, "I found a function block '{{unknown ...}}' but don't recognise the function name. Ignoring.") J.convert_html(hs, allvars)) == "unknown fun  and see."
end


@testset "h-insert" begin
    # Julia 0.7 complains if there's no global here.
    global temp_rnd = joinpath(J.PATHS[:src_html], "temp.rnd")
    write(temp_rnd, "some random text to insert")
    hs = raw"""
        Trying to insert: {{ insert temp.rnd }} and see.
        """
    allvars = J.PageVars()
    @test J.convert_html(hs, allvars) == "Trying to insert: some random text to insert and see.\n"

    hs = raw"""Trying to insert: {{ insert nope.rnd }} and see."""
    @test (@test_logs (:warn, "I found an {{insert ...}} block and tried to insert '$(joinpath(J.PATHS[:src_html], "nope.rnd"))' but I couldn't find the file. Ignoring.") J.convert_html(hs, allvars)) == "Trying to insert:  and see."
end


@testset "cond-insert" begin
    allvars = J.PageVars(
        "author" => "Stefan Zweig" => (String, Nothing),
        "date_format" => "U dd, yyyy" => (String,),
        "isnotes" => true => (Bool,))
    hs = "foot {{if isnotes}} {{fill author}}{{end}}"
    rhs = J.convert_html(hs, allvars)
    @test rhs == "foot  Stefan Zweig"
end


@testset "cond-insert 2" begin
    allvars = J.PageVars(
        "author" => "Stefan Zweig" => (String, Nothing),
        "date_format" => "U dd, yyyy" => (String,),
        "isnotes" => true => (Bool,))
    hs = "foot {{isdef author}} {{fill author}}{{end}}"
    rhs = J.convert_html(hs, allvars)
    @test rhs == "foot  Stefan Zweig"
    hs2 = "foot {{isnotdef blogname}}hello{{end}}"
    rhs = J.convert_html(hs2, allvars)
    @test rhs == "foot hello"
end

@testset "escape-coms" begin
    allvars = J.PageVars(
        "author" => "Stefan Zweig" => (String, Nothing),
        "date_format" => "U dd, yyyy" => (String,),
        "isnotes" => true => (Bool,))
    hs = "foot <!-- {{ fill blahblah }} {{ if v1 }} --> {{isdef author}} {{fill author}}{{end}}"
    rhs = J.convert_html(hs, allvars)
    @test rhs == "foot <!-- {{ fill blahblah }} {{ if v1 }} -->  Stefan Zweig"
end


@testset "Cblock+empty" begin # refers to #96
    allvars = J.PageVars(
        "b1" => false => (Bool,),
        "b2" => true => (Bool,))

    jdc = x->J.convert_html(x, allvars)

    # flag b1 is false
    @test "{{if b1}} blah {{ else }} blih {{ end }}" |> jdc == " blih " # else
    @test "{{if b1}} {{ else }} blih {{ end }}" |> jdc == " blih "      # else

    # flag b2 is true
    @test "{{if b2}} blah {{ else }} blih {{ end }}" |> jdc == " blah " # if
    @test "{{if b2}} blah {{ else }} {{ end }}" |> jdc == " blah "      # if
    @test "{{if b2}} blah {{ end }}" |> jdc == " blah "                 # if

    @test "{{if b1}} blah {{ else }} {{ end }}" |> jdc == " " # else, empty
    @test "{{if b1}} {{ else }} {{ end }}" |> jdc == " "      # else, empty
    @test "{{if b1}} blah {{ end }}" |> jdc == ""            # else, empty
    @test "{{if b2}} {{ else }} {{ end }}" |> jdc == " "      # if, empty
    @test "{{if b2}} {{ else }} blih {{ end }}" |> jdc == " " # if, empty
end


@testset "Cond ispage" begin
    allvars = J.PageVars()

    hs = raw"""
        Some text then {{ ispage index.html }} blah {{ end }} but
        {{isnotpage blah.html ya/xx}} blih {{end}} done.
        """

    J.CUR_PATH[] = "index.md"
    @test J.convert_html(hs, allvars) == "Some text then  blah  but\n blih  done.\n"
end
