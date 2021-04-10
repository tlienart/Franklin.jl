@testset "misc-html" begin
    fs()
    λ = "blah/blah.ext"
    set_curpath("cpB/blah.md")
    @test F.html_ahref(λ, 1)           == "<a href=\"$λ\">1</a>"
    @test F.html_ahref(λ, "bb")        == "<a href=\"$λ\">bb</a>"
    @test F.html_ahref_key("cc", "dd") == "<a href=\"#cc\">dd</a>"
end

@testset "misc-html 2" begin
   h = "<div class=\"foo\">blah</div>"
   @test !F.is_html_escaped(h)
   @test F.html_code(h, "html") == """<pre><code class="language-html">&lt;div class&#61;&quot;foo&quot;&gt;blah&lt;/div&gt;</code></pre>"""
   he = Markdown.htmlesc(h)
   @test F.is_html_escaped(he)
   @test F.html_code(h, "html") == F.html_code(h, "html")
end

@testset "html/hide" begin
    c = """
        a=5
        b=7
        """
    @test F.html_skip_hidden(c, "foo") == c
    c = """
        #hideall
        a=5
        b=7
        """
    @test F.html_skip_hidden(c, "julia") == ""
    c = """
        a=5 #hide
        b=7
        """
    @test F.html_skip_hidden(c, "julia") == "b=7"
end

@testset "html_code" begin
    c = """
        using Random
        Random.seed!(555) # hide
        a = randn()
        b = a + 5
        """
    @test F.html_code(c, "julia") ==
        """<pre><code class="language-julia">$(F.htmlesc("""using Random
        a = randn()
        b = a + 5"""))</code></pre>"""
end

@testset "html_content" begin
    h = F.html_content("div", "foo bar"; class="container", id="body")
    @test h == "<div class=\"container\" id=\"body\">foo bar</div>"
end

@testset "fd2text" begin
    h = F.fd2text(
        """
        A **B** `C` [D](https://julialang.org)
        - E
        - F
        G < H
        """
    )
    @test isapproxstr(h, """
        A B C D E F G &lt; H
        """)
end
