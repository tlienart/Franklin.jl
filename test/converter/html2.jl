@testset "Non-nested" begin
    allvars = J.PageVars(
        "a" => false => (Bool,),
        "b" => false => (Bool,))

    hs = """A{{if a}}B{{elseif b}}C{{else}}D{{end}}E"""

    tokens          = J.find_tokens(hs, J.HTML_TOKENS, J.HTML_1C_TOKENS)
    hblocks, tokens = J.find_all_ocblocks(tokens, J.HTML_OCB)
    qblocks         = J.qualify_html_hblocks(hblocks)

    J.set_vars!(allvars, ["a"=>"true","b"=>"false"])
    fhs = J.process_html_qblocks(hs, allvars, qblocks)
    @test isapproxstr(fhs, "ABE")

    J.set_vars!(allvars, ["a"=>"false","b"=>"true"])
    fhs = J.process_html_qblocks(hs, allvars, qblocks)
    @test isapproxstr(fhs, "ACE")

    J.set_vars!(allvars, ["a"=>"false","b"=>"false"])
    fhs = J.process_html_qblocks(hs, allvars, qblocks)
    @test isapproxstr(fhs, "ADE")
end

@testset "Nested" begin
    allvars = J.PageVars(
        "a" => false => (Bool,),
        "b" => false => (Bool,),
        "c" => false => (Bool,))

    hs = """A {{if a}} B {{elseif b}} C {{if c}} D {{end}} {{else}} E {{end}} F"""

    tokens          = J.find_tokens(hs, J.HTML_TOKENS, J.HTML_1C_TOKENS)
    hblocks, tokens = J.find_all_ocblocks(tokens, J.HTML_OCB)
    qblocks         = J.qualify_html_hblocks(hblocks)

    J.set_vars!(allvars, ["a"=>"true"])
    fhs = J.process_html_qblocks(hs, allvars, qblocks)
    @test isapproxstr(fhs, "ABF")

    J.set_vars!(allvars, ["a"=>"false", "b"=>"true", "c"=>"false"])
    fhs = J.process_html_qblocks(hs, allvars, qblocks)
    @test isapproxstr(fhs, "ACF")

    J.set_vars!(allvars, ["a"=>"false", "b"=>"true", "c"=>"true"])
    fhs = J.process_html_qblocks(hs, allvars, qblocks)
    @test isapproxstr(fhs, "ACDF")

    J.set_vars!(allvars, ["a"=>"false", "b"=>"false"])
    fhs = J.process_html_qblocks(hs, allvars, qblocks)
    @test isapproxstr(fhs, "AEF")
end


@testset "Bad cases" begin
    # Lonely End block
    s = """A {{end}}"""
    @test_throws J.HTMLBlockError J.convert_html(s, J.PageVars())

    # Inbalanced
    s = """A {{if a}} B {{if b}} C {{else}} {{end}}"""
    @test_throws J.HTMLBlockError J.convert_html(s, J.PageVars())

    # Some of the conditions are not bools
    allvars = J.PageVars(
        "a" => false => (Bool,),
        "b" => false => (Bool,),
        "c" => "Hello" => (String,))
    s = """A {{if a}} A {{elseif c}} B {{end}}"""
    @test_throws J.HTMLBlockError J.convert_html(s, allvars)
end
