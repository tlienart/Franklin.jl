@testset "strings" begin
    st = "blah"

    @test J.str(st) == "blah"

    sst = SubString("blahblah", 1:4)
    @test sst == "blah"
    @test J.str(sst) == "blahblah"

    sst = SubString("blah✅💕and etcσ⭒ but ∃⫙∀ done", 1:27)
    @test J.to(sst) == 27
end
