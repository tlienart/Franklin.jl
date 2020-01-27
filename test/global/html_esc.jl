# See https://github.com/tlienart/Franklin.jl/issues/326

@testset "Issue 326" begin
    h1 = "<div class=\"hello\">Blah</div>"
    h1e = Markdown.htmlesc(h1)
    @test J.is_html_escaped(h1e)
    @test J.html_unescape(h1e) == h1
end
