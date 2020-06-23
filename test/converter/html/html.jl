@testset "Cblock+h-fill" begin
    F.def_GLOBAL_VARS!()
    F.def_LOCAL_VARS!()
    F.set_vars!(F.LOCAL_VARS, ["v1"=>"\"INPUT1\"", "b1"=>"false", "b2"=>"true"])
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
    @test F.convert_html(hs) == "Some text then INPUT1 and\n\nother stuff\n\nfinal text\n"

    for expr in ("isdef", "ifdef")
        hs = """abc {{$expr no}}yada{{end}} def"""
        @test F.convert_html(hs) == "abc  def"
    end

    hs = raw"""abc {{ fill nope }} ... """
    @test (@test_logs (:warn, "I found a '{{fill nope}}' but I do not know the variable 'nope'. Ignoring.") F.convert_html(hs))  == "abc  ... "

    hs = raw"""unknown fun {{ unknown fun }} and see."""
    @test (@test_logs (:warn, "I found a function block '{{unknown ...}}' but I don't recognise the function name. Ignoring.") F.convert_html(hs)) == "unknown fun  and see."
end


@testset "h-insert" begin
    fs1()
    temp_rnd = joinpath(F.PATHS[:src_html], "temp.rnd")
    write(temp_rnd, "some random text to insert")
    hs = raw"""
        Trying to insert: {{ insert temp.rnd }} and see.
        """
    @test F.convert_html(hs) == "Trying to insert: some random text to insert and see.\n"

    hs = raw"""Trying to insert: {{ insert nope.rnd }} and see."""
    @test (@test_logs (:warn, "I found an {{insert ...}} block and tried to insert '$(joinpath(F.PATHS[:src_html], "nope.rnd"))' but I couldn't find the file. Ignoring.") F.convert_html(hs)) == "Trying to insert:  and see."
end

@testset "h-insert-fs2" begin
    fs2()
    temp_rnd = joinpath(F.PATHS[:layout], "temp.rnd")
    write(temp_rnd, "some random text to insert")
    hs = raw"""
        Trying to insert: {{ insert temp.rnd }} and see.
        """
    @test F.convert_html(hs) == "Trying to insert: some random text to insert and see.\n"

    hs = raw"""Trying to insert: {{ insert nope.rnd }} and see."""
    @test (@test_logs (:warn, "I found an {{insert ...}} block and tried to insert '$(joinpath(F.PATHS[:layout], "nope.rnd"))' but I couldn't find the file. Ignoring.") F.convert_html(hs)) == "Trying to insert:  and see."
end


@testset "cond-insert" begin
    F.set_vars!(F.LOCAL_VARS, [
        "author" => "\"Stefan Zweig\"",
        "date_format" => "\"U dd, yyyy\"",
        "isnotes" => "true"])
    hs = "foot {{if isnotes}} {{fill author}}{{end}}"
    rhs = F.convert_html(hs)
    @test rhs == "foot  Stefan Zweig"
end


@testset "cond-insert 2" begin
    F.set_vars!(F.LOCAL_VARS, [
        "author" => "\"Stefan Zweig\"",
        "date_format" => "\"U dd, yyyy\"",
        "isnotes" => "true"])
    hs = "foot {{isdef author}} {{fill author}}{{end}}"
    rhs = F.convert_html(hs)
    @test rhs == "foot  Stefan Zweig"
    for expr in ("isnotdef", "ifnotdef", "isndef", "ifndef")
        hs2 = "foot {{$expr blogname}}hello{{end}}"
        rhs = F.convert_html(hs2)
        @test rhs == "foot hello"
    end
end

@testset "escape-coms" begin
    F.set_vars!(F.LOCAL_VARS, [
        "author" => "\"Stefan Zweig\"",
        "date_format" => "\"U dd, yyyy\"",
        "isnotes" => "true"])
    hs = "foot <!-- {{ fill blahblah }} {{ if v1 }} --> {{isdef author}} {{fill author}}{{end}}"
    rhs = F.convert_html(hs)
    @test rhs == "foot <!-- {{ fill blahblah }} {{ if v1 }} -->  Stefan Zweig"
end


@testset "Cblock+empty" begin # refers to #96
    F.set_vars!(F.LOCAL_VARS, [
        "b1" => "false",
        "b2" => "true"])

    fdc = x->F.convert_html(x)

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
    hs = raw"""
        Some text then {{ ispage index.html }} blah {{ end }} but
        {{isnotpage blah.html ya/xx}} blih {{end}} done.
        """

    set_curpath("index.md")
    @test F.convert_html(hs) == "Some text then  blah  but\n blih  done.\n"

    set_curpath("blah/blih.md")
    hs = raw"""
        A then {{ispage blah/*}}yes{{end}} but not {{isnotpage blih/*}}no{{end}} E.
        """
    @test F.convert_html(hs) == "A then yes but not no E.\n"

    set_curpath("index.md")
end

@testset "Cond isempty" begin
    F.def_LOCAL_VARS!()
    F.set_vars!(F.LOCAL_VARS, [
        "b1" => "\"\"",
        "b2" => "\"hello\""])
    fdc = x->F.convert_html(x)

    @test "{{isempty b1}}blah{{else}}blih{{end}}" |> fdc == "blah"
    @test "{{isnotempty b2}}blah{{else}}blih{{end}}" |> fdc == "blah"
    @test "{{isempty b2}}blah{{else}}blih{{end}}" |> fdc == "blih"
    @test "{{isnotempty b1}}blah{{else}}blih{{end}}" |> fdc == "blih"
end
