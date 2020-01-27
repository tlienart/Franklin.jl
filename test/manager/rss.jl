@testset "RSSItem" begin
    rss = F.RSSItem(
        "title", "www.link.com", "description", "author@author.com", "category",
        "www.comments.com", "enclosure", Date(2012,12,12))
    @test rss.title == "title"
    @test rss.link == "www.link.com"
    @test rss.description == "description"
    @test rss.author == "author@author.com"
    @test rss.category == "category"
    @test rss.comments == "www.comments.com"
    @test rss.enclosure == "enclosure"
    @test rss.pubDate == Date(2012,12,12)
end

@testset "RSSbasics" begin
    empty!(F.RSS_DICT)
    F.def_GLOBAL_VARS!()
    F.set_var!(F.GLOBAL_VARS, "website_title", "Website title")
    F.set_var!(F.GLOBAL_VARS, "website_descr", "Website descr")
    F.set_var!(F.GLOBAL_VARS, "website_url", "https://github.com/tlienart/Franklin.jl/")
    F.def_LOCAL_VARS!()
    set_curpath("hey/ho.md")
    F.set_var!(F.LOCAL_VARS, "rss_title", "title")
    F.set_var!(F.LOCAL_VARS, "rss", "A **description** done.")
    F.set_var!(F.LOCAL_VARS, "rss_author", "chuck@norris.com")

    item = F.add_rss_item()
    @test item.title == "title"
    @test item.description == "A <strong>description</strong> done.\n"
    @test item.author == "chuck@norris.com"
    # unchanged bc all three fallbacks lead to Data(1)
    @test item.pubDate == Date(1)

    F.set_var!(F.LOCAL_VARS, "rss_title", "")
    @test @test_logs (:warn, "Found an RSS description but no title for page /hey/ho.html.") F.add_rss_item().title == ""

    @test F.RSS_DICT["/hey/ho.html"].description == item.description

    # Generation
    F.PATHS[:folder] = td
    F.rss_generator()
    feed = joinpath(F.PATHS[:folder], "feed.xml")
    @test isfile(feed)
    fc = prod(readlines(feed, keep=true))
    @test occursin("<description><![CDATA[A <strong>description</strong> done.", fc)
end
