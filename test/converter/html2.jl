@testset "Non-nested" begin
    allvars = F.PageVars(
        "a" => false => (Bool,),
        "b" => false => (Bool,))

    hs = """A{{if a}}B{{elseif b}}C{{else}}D{{end}}E"""

    tokens          = F.find_tokens(hs, F.HTML_TOKENS, F.HTML_1C_TOKENS)
    hblocks, tokens = F.find_all_ocblocks(tokens, F.HTML_OCB)
    qblocks         = F.qualify_html_hblocks(hblocks)

    F.set_vars!(allvars, ["a"=>"true","b"=>"false"])
    fhs = F.process_html_qblocks(hs, allvars, qblocks)
    @test isapproxstr(fhs, "ABE")

    F.set_vars!(allvars, ["a"=>"false","b"=>"true"])
    fhs = F.process_html_qblocks(hs, allvars, qblocks)
    @test isapproxstr(fhs, "ACE")

    F.set_vars!(allvars, ["a"=>"false","b"=>"false"])
    fhs = F.process_html_qblocks(hs, allvars, qblocks)
    @test isapproxstr(fhs, "ADE")
end

@testset "Nested" begin
    allvars = F.PageVars(
        "a" => false => (Bool,),
        "b" => false => (Bool,),
        "c" => false => (Bool,))

    hs = """A {{if a}} B {{elseif b}} C {{if c}} D {{end}} {{else}} E {{end}} F"""

    tokens          = F.find_tokens(hs, F.HTML_TOKENS, F.HTML_1C_TOKENS)
    hblocks, tokens = F.find_all_ocblocks(tokens, F.HTML_OCB)
    qblocks         = F.qualify_html_hblocks(hblocks)

    F.set_vars!(allvars, ["a"=>"true"])
    fhs = F.process_html_qblocks(hs, allvars, qblocks)
    @test isapproxstr(fhs, "ABF")

    F.set_vars!(allvars, ["a"=>"false", "b"=>"true", "c"=>"false"])
    fhs = F.process_html_qblocks(hs, allvars, qblocks)
    @test isapproxstr(fhs, "ACF")

    F.set_vars!(allvars, ["a"=>"false", "b"=>"true", "c"=>"true"])
    fhs = F.process_html_qblocks(hs, allvars, qblocks)
    @test isapproxstr(fhs, "ACDF")

    F.set_vars!(allvars, ["a"=>"false", "b"=>"false"])
    fhs = F.process_html_qblocks(hs, allvars, qblocks)
    @test isapproxstr(fhs, "AEF")
end


@testset "Bad cases" begin
    # Lonely End block
    s = """A {{end}}"""
    @test_throws F.HTMLBlockError F.convert_html(s, F.PageVars())

    # Inbalanced
    s = """A {{if a}} B {{if b}} C {{else}} {{end}}"""
    @test_throws F.HTMLBlockError F.convert_html(s, F.PageVars())

    # Some of the conditions are not bools
    allvars = F.PageVars(
        "a" => false => (Bool,),
        "b" => false => (Bool,),
        "c" => "Hello" => (String,))
    s = """A {{if a}} A {{elseif c}} B {{end}}"""
    @test_throws F.HTMLBlockError F.convert_html(s, allvars)
end
