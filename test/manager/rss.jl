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
    fs()
    empty!(F.RSS_DICT)
    F.def_GLOBAL_VARS!()
    F.set_var!(F.GLOBAL_VARS, "website_title", "Website title")
    F.set_var!(F.GLOBAL_VARS, "website_descr", "Website descr")
    F.set_var!(F.GLOBAL_VARS, "website_url", "https://github.com/tlienart/Franklin.jl/")

    # Page 1 with tags = ["foo"]
    F.def_LOCAL_VARS!()
    set_curpath("hey/hello.md")
    F.set_var!(F.LOCAL_VARS, "rss_title", "title 1")
    F.set_var!(F.LOCAL_VARS, "rss", "Page with tag foo.")
    F.set_var!(F.LOCAL_VARS, "rss_pubdate", Date(2020, 10, 27))
    F.set_var!(F.LOCAL_VARS, "tags", ["foo"])

    item, tags = F.add_rss_item()
    @test item.title == "title 1"
    @test item.description == "Page with tag foo.\n"
    @test item.author == ""
    @test item.pubDate == Date(2020, 10, 27)
    @test tags == ["foo"]
    @test F.RSS_DICT["/hey/hello/"][1].description == item.description
    @test F.RSS_DICT["/hey/hello/"][2] == ["foo"]

    # Page 2 with tags = ["foo", "bar"]
    F.def_LOCAL_VARS!()
    set_curpath("hey/ho.md")
    F.set_var!(F.LOCAL_VARS, "rss_title", "title 2")
    F.set_var!(F.LOCAL_VARS, "rss", "A **description** done. Page with tags foo and bar.")
    F.set_var!(F.LOCAL_VARS, "rss_pubdate", Date(2020, 10, 30))
    F.set_var!(F.LOCAL_VARS, "rss_author", "chuck@norris.com")
    F.set_var!(F.LOCAL_VARS, "tags", ["foo", "bar"])

    item, tags = F.add_rss_item()
    @test item.title == "title 2"
    @test item.description == "A <strong>description</strong> done. Page with tags foo and bar.\n"
    @test item.author == "chuck@norris.com"
    @test item.pubDate == Date(2020, 10, 30)
    @test tags == ["foo", "bar"]
    @test F.RSS_DICT["/hey/ho/"][1].description == item.description
    @test F.RSS_DICT["/hey/ho/"][2] == ["foo", "bar"]

    # Generation
    F.PATHS[:folder] = td
    F.rss_generator()
    ## Global feed
    feed = joinpath(F.PATHS[:site], "feed.xml")
    @test isfile(feed)
    fc = read(feed, String)
    @test occursin("<description><![CDATA[A <strong>description</strong> done. Page with tags foo and bar.", fc)
    @test occursin("<description><![CDATA[Page with tag foo.", fc)
    @test occursin("<link>https://github.com/tlienart/Franklin.jl/hey/ho/</link>", fc)
    @test occursin("<link>https://github.com/tlienart/Franklin.jl/hey/hello/</link>", fc)
    @test occursin("<pubDate>Fri, 30 Oct 2020 00:00:00 UT</pubDate>", fc)
    @test occursin("<pubDate>Tue, 27 Oct 2020 00:00:00 UT</pubDate>", fc)
    @test occursin("<atom:link href=\"https://github.com/tlienart/Franklin.jl/feed.xml\" rel=\"self\" type=\"application/rss+xml\" />", fc)
    @test findfirst("Fri, 30 Oct 2020", fc) < findfirst("27 Oct 2020", fc) # ordered by pubDate

    ## Tag filtered feeds
    ### foo tag
    feed = joinpath(F.PATHS[:tag], "foo", "feed.xml")
    @test isfile(feed)
    foo_feed = read(feed, String)
    @test occursin("<description><![CDATA[A <strong>description</strong> done. Page with tags foo and bar.", foo_feed)
    @test occursin("<description><![CDATA[Page with tag foo.", foo_feed)
    @test occursin("<pubDate>Fri, 30 Oct 2020 00:00:00 UT</pubDate>", foo_feed)
    @test occursin("<pubDate>Tue, 27 Oct 2020 00:00:00 UT</pubDate>", foo_feed)
    @test occursin("<atom:link href=\"https://github.com/tlienart/Franklin.jl/tag/foo/feed.xml\" rel=\"self\" type=\"application/rss+xml\" />", foo_feed)
    @test findfirst("Fri, 30 Oct 2020", foo_feed) < findfirst("27 Oct 2020", foo_feed) # ordered by pubDate
    ### bar tag
    feed = joinpath(F.PATHS[:tag], "bar", "feed.xml")
    @test isfile(feed)
    bar_feed = read(feed, String)
    @test occursin("<description><![CDATA[A <strong>description</strong> done. Page with tags foo and bar.", bar_feed)
    @test !occursin("<description><![CDATA[Page with tag foo.", bar_feed)
    @test occursin("<pubDate>Fri, 30 Oct 2020 00:00:00 UT</pubDate>", bar_feed)
    @test !occursin("<pubDate>Tue, 27 Oct 2020 00:00:00 UT</pubDate>", bar_feed)
    @test occursin("<atom:link href=\"https://github.com/tlienart/Franklin.jl/tag/bar/feed.xml\" rel=\"self\" type=\"application/rss+xml\" />", bar_feed)
end
