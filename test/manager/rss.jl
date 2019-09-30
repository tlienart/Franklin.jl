@testset "RSSItem" begin
    rss = J.RSSItem(
        "title", "link", "description", "author", "category",
        "comments", "enclosure", Date(2012,12,12))
    @test rss.title == "title"
    @test rss.link == "link"
    @test rss.description == "description"
    @test rss.author == "author"
    @test rss.category == "category"
    @test rss.comments == "comments"
    @test rss.enclosure == "enclosure"
    @test rss.pubDate == Date(2012,12,12)
end

@testset "RSSbasics" begin
    empty!(J.RSS_DICT)
    J.CUR_PATH[] = "hey/ho.md"
    J.set_var!(J.GLOBAL_PAGE_VARS, "website_title", "Website title")
    J.set_var!(J.GLOBAL_PAGE_VARS, "website_descr", "Website descr")
    J.set_var!(J.GLOBAL_PAGE_VARS, "website_url", "https://github.com/tlienart/JuDoc.jl/")
    jdv = merge(J.GLOBAL_PAGE_VARS, copy(J.LOCAL_PAGE_VARS))
    J.set_var!(jdv, "rss_title", "title")
    J.set_var!(jdv, "rss", "A **description** done.")
    J.set_var!(jdv, "author", "Chuck")

    item = J.add_rss_item(jdv)
    @test item.title == "title"
    @test item.description == "<p>A <strong>description</strong> done.</p>\n"
    @test item.author == "Chuck"
    # unchanged bc all three fallbacks lead to Data(1)
    @test item.pubDate == Date(1)

    J.set_var!(jdv, "rss_title", "")
    @test @test_logs (:warn, "Found an RSS description but no title for page /hey/ho.html.") J.add_rss_item(jdv).title == ""

    @test J.RSS_DICT["/hey/ho.html"].description == item.description

    # Generation
    J.PATHS[:folder] = td
    J.rss_generator()
    feed = joinpath(J.PATHS[:folder], "feed.xml")
    @test isfile(feed)
    fc = prod(readlines(feed, keep=true))
    @test occursin("<item>\n    <title></title>\n    <link>https://github.com/tlienart/JuDoc.jl/hey/ho.html</link>\n    <description><p>A <strong>description</strong> done.</p>\n</description>", fc)
end
