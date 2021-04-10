@testset "rss_prep" begin
    F.def_GLOBAL_VARS!()
    F.set_var!(F.GLOBAL_VARS, "generate_rss", false)
    F.set_var!(F.GLOBAL_VARS, "website_description", "Description")
    F.set_var!(F.GLOBAL_VARS, "website_url", "URL")
    F.set_var!(F.GLOBAL_VARS, "website_title", "Title")
    F.prepare_for_rss()
    # because things are defined, switch to true
    @test F.globvar(:generate_rss)
    @test isdir(F.path(:rss))
    @test isfile(joinpath(F.path(:rss), "head.xml"))
    @test isfile(joinpath(F.path(:rss), "item.xml"))
end
