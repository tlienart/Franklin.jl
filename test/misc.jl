# This is a test file to make codecov happy, technically all of the
# tests here are already done / integrated within other tests.

@testset "strings" begin
    st = "blah"

    @test J.str(st) == "blah"

    sst = SubString("blahblah", 1:4)
    @test sst == "blah"
    @test J.str(sst) == "blahblah"

    sst = SubString("blah✅💕and etcσ⭒ but ∃⫙∀ done", 1:27)
    @test J.to(sst) == 27
end


@testset "ocblock" begin

    st = "This is a block <!--comment--> and done"
    τ = J.find_tokens(st, J.MD_TOKENS, J.MD_1C_TOKENS)
    ocb = J.OCBlock(:COMMENT, (τ[1]=>τ[2]))
    @test J.otok(ocb) == τ[1]
    @test J.ctok(ocb) == τ[2]
end


@testset "isexactly" begin

    steps, b, λ = J.isexactly("<!--")
    @test steps == length("<!--") - 1 # minus start char
    @test b == false
    @test λ("<!--") == true
    @test λ("<--") == false

    steps, b, λ = J.isexactly("\$", ['\$'])
    @test steps == 1
    @test b == true
    @test λ("\$\$") == true
    @test λ("\$a") == false
    @test λ("a\$") == false

    steps, b, λ = J.isexactly("\$", ['\$'], false)
    @test steps == 1
    @test b == true
    @test λ("\$\$") == false
    @test λ("\$a") == true
    @test λ("a\$") == false

    steps, b, λ = J.incrlook(isletter)
    @test steps == 0
    @test b == false
    @test λ('c') == true
    @test λ('[') == false
end
