@testset "Find Tokens" begin
    a = raw"""some markdown then `code` and @@dname block @@""" * JuDoc.EOS

    tokens = JuDoc.find_tokens(a, JuDoc.MD_TOKENS, JuDoc.MD_1C_TOKENS)
    @test tokens[1].name == :CODE_SINGLE
    @test tokens[2].name == :CODE_SINGLE
    @test tokens[3].name == :DIV_OPEN
    @test tokens[3].ss == "@@dname"
    @test tokens[4].ss == "@@"
end
