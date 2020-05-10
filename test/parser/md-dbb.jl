@testset "Bad cases" begin
    F.def_LOCAL_VARS!()
    # Lonely End block
    s = """A {{end}}"""
    @test_throws F.HTMLBlockError F.convert_html(s)

    # Inbalanced
    s = """A {{if a}} B {{if b}} C {{else}} {{end}}"""
    @test_throws F.HTMLBlockError F.convert_html(s)

    # Some of the conditions are not bools
    F.set_vars!(F.LOCAL_VARS, [
        "a" => "false",
        "b" => "false",
        "c" => "\"Hello\""])
    s = """A {{if a}} A {{elseif c}} B {{end}}"""
    @test_throws F.HTMLBlockError F.convert_html(s)
end


@testset "Script" begin
    F.def_LOCAL_VARS!()
    F.set_var!(F.LOCAL_VARS, "hasmath", true)
    s = """
        Hasmath: {{hasmath}}
        <script>{{hasmath}}</script>
        <script src="...">{{hasmath}}</script>
        """
    @test isapproxstr(F.convert_html(s), """
        Hasmath: true
        <script>{{hasmath}}</script>
        <script src="...">{{hasmath}}</script>
        """)
end

# issue #482
@testset "div-dbb" begin
    Franklin.eval(:(hfun_bar(p) = string(round(sqrt(Meta.parse(p[1])), digits=1)) ))
    s = "@@B @@A {{author}} @@\n@@ <!-- html -->\n" |> fd2html
    @test isapproxstr(s, """
        <div class=\"B\"><div class=\"A\">THE AUTHOR</div></div>
        """)
    s = "**{{author}}**" |> fd2html
    @test isapproxstr(s, "<p><strong>THE AUTHOR</strong></p>")
    s = raw"\style{font-weight:bold;}{ {{author}} }" |> fd2html
    @test isapproxstr(s, """
        <span style="font-weight:bold;">THE AUTHOR</span>
        """)
    s = raw"@@bold {{bar 4}} @@" |> fd2html
    @test isapproxstr(s, """
        <div class="bold">2.0</div>
        """)
end
