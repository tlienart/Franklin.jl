# simple test that things get created
@testset "RSS gen" begin
    f = joinpath(p, "basic", "__site", "feed.xml")
    @test isfile(f)
    fc = prod(readlines(f, keep=true))

    @test occursin(raw"""<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">""", fc)
    @test occursin(raw"""<title>Franklin Template</title>""", fc)
    @test occursin(raw"""<description><![CDATA[Example website using Franklin
  ]]></description>""", fc)
    @test !occursin(raw"""<author>""", fc)
    @test occursin(raw"""<link>https://tlienart.github.io/FranklinTemplates.jl/menu1/index.html</link>""", fc)
    @test occursin(raw"""<description><![CDATA[A short description of the page which would serve as <strong>blurb</strong> in a <code>RSS</code> feed;""", fc)
end

@testset "Sitemap gen" begin
    f = joinpath(p, "basic", "__site", "sitemap.xml")
    @test isfile(f)
    fc = prod(readlines(f, keep=true))

    @test occursin(raw"""
        <?xml version="1.0" encoding="utf-8" standalone="yes" ?>
        <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">""", fc)
    # check pages
    for pg in ("", "menu1", "menu2", "menu3")
        pgg = joinpath(pg, "index.html")
        @test occursin("""
            <loc>https://tlienart.github.io/FranklinTemplates.jl/$pgg</loc>""", fc)
    end
end

@testset "Robots.txt gen" begin
    f = joinpath(p, "basic", "__site", "robots.txt")
    @test isfile(f)
    fc = prod(readlines(f, keep=true))

    @test occursin(raw"""
        Sitemap: https://tlienart.github.io/FranklinTemplates.jl/sitemap.xml""", fc)
end
