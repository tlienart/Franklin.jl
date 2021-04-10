@testset "robots" begin
    F.def_LOCAL_VARS!()
    F.add_disallow_item()
    @test F.url_curpage() in F.DISALLOW
end
