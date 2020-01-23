@testset "Cblock+h-fill" begin
    allvars = F.PageVars(
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
    @test F.convert_html(hs, allvars) == "Some text then INPUT1 and\n\nother stuff\n\nfinal text\n"

    hs = raw"""
        abc {{isdef no}}yada{{end}} def
        """
    @test F.convert_html(hs, allvars) == "abc  def\n"

    hs = raw"""abc {{ fill nope }} ... """
    @test (@test_logs (:warn, "I found a '{{fill nope}}' but I do not know the variable 'nope'. Ignoring.") F.convert_html(hs, allvars))  == "abc  ... "

    hs = raw"""unknown fun {{ unknown fun }} and see."""
    @test (@test_logs (:warn, "I found a function block '{{unknown ...}}' but don't recognise the function name. Ignoring.") F.convert_html(hs, allvars)) == "unknown fun  and see."
end


@testset "h-insert" begin
    # Julia 0.7 complains if there's no global here.
    global temp_rnd = joinpath(F.PATHS[:src_html], "temp.rnd")
    write(temp_rnd, "some random text to insert")
    hs = raw"""
        Trying to insert: {{ insert temp.rnd }} and see.
        """
    allvars = F.PageVars()
    @test F.convert_html(hs, allvars) == "Trying to insert: some random text to insert and see.\n"

    hs = raw"""Trying to insert: {{ insert nope.rnd }} and see."""
    @test (@test_logs (:warn, "I found an {{insert ...}} block and tried to insert '$(joinpath(F.PATHS[:src_html], "nope.rnd"))' but I couldn't find the file. Ignoring.") F.convert_html(hs, allvars)) == "Trying to insert:  and see."
end


@testset "cond-insert" begin
    allvars = F.PageVars(
        "author" => "Stefan Zweig" => (String, Nothing),
        "date_format" => "U dd, yyyy" => (String,),
        "isnotes" => true => (Bool,))
    hs = "foot {{if isnotes}} {{fill author}}{{end}}"
    rhs = F.convert_html(hs, allvars)
    @test rhs == "foot  Stefan Zweig"
end


@testset "cond-insert 2" begin
    allvars = F.PageVars(
        "author" => "Stefan Zweig" => (String, Nothing),
        "date_format" => "U dd, yyyy" => (String,),
        "isnotes" => true => (Bool,))
    hs = "foot {{isdef author}} {{fill author}}{{end}}"
    rhs = F.convert_html(hs, allvars)
    @test rhs == "foot  Stefan Zweig"
    hs2 = "foot {{isnotdef blogname}}hello{{end}}"
    rhs = F.convert_html(hs2, allvars)
    @test rhs == "foot hello"
end

@testset "escape-coms" begin
    allvars = F.PageVars(
        "author" => "Stefan Zweig" => (String, Nothing),
        "date_format" => "U dd, yyyy" => (String,),
        "isnotes" => true => (Bool,))
    hs = "foot <!-- {{ fill blahblah }} {{ if v1 }} --> {{isdef author}} {{fill author}}{{end}}"
    rhs = F.convert_html(hs, allvars)
    @test rhs == "foot <!-- {{ fill blahblah }} {{ if v1 }} -->  Stefan Zweig"
end


@testset "Cblock+empty" begin # refers to #96
    allvars = F.PageVars(
        "b1" => false => (Bool,),
        "b2" => true => (Bool,))

    fdc = x->F.convert_html(x, allvars)

    # flag b1 is false
    @test "{{if b1}} blah {{ else }} blih {{ end }}" |> fdc == " blih " # else
    @test "{{if b1}} {{ else }} blih {{ end }}" |> fdc == " blih "      # else

    # flag b2 is true
    @test "{{if b2}} blah {{ else }} blih {{ end }}" |> fdc == " blah " # if
    @test "{{if b2}} blah {{ else }} {{ end }}" |> fdc == " blah "      # if
    @test "{{if b2}} blah {{ end }}" |> fdc == " blah "                 # if

    @test "{{if b1}} blah {{ else }} {{ end }}" |> fdc == " " # else, empty
    @test "{{if b1}} {{ else }} {{ end }}" |> fdc == " "      # else, empty
    @test "{{if b1}} blah {{ end }}" |> fdc == ""            # else, empty
    @test "{{if b2}} {{ else }} {{ end }}" |> fdc == " "      # if, empty
    @test "{{if b2}} {{ else }} blih {{ end }}" |> fdc == " " # if, empty
end

@testset "Cond ispage" begin
    allvars = F.PageVars()

    hs = raw"""
        Some text then {{ ispage index.html }} blah {{ end }} but
        {{isnotpage blah.html ya/xx}} blih {{end}} done.
        """

    F.FD_ENV[:CUR_PATH] = "index.md"
    @test F.convert_html(hs, allvars) == "Some text then  blah  but\n blih  done.\n"

    F.FD_ENV[:CUR_PATH] = "blah/blih.md"
    hs = raw"""
        A then {{ispage blah/*}}yes{{end}} but not {{isnotpage blih/*}}no{{end}} E.
        """
    @test F.convert_html(hs, allvars) == "A then yes but not no E.\n"

    F.FD_ENV[:CUR_PATH] = "index.md"
end
