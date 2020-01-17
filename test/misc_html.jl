@testset "misc-html" begin
    λ = "blah/blah.ext"
    J.JD_ENV[:CUR_PATH] = "pages/cpB/blah.md"
    @test J.html_ahref(λ, 1) == "<a href=\"$λ\">1</a>"
    @test J.html_ahref(λ, "bb") == "<a href=\"$λ\">bb</a>"
    @test J.html_ahref_key("cc", "dd") == "<a href=\"/pub/cpB/blah.html#cc\">dd</a>"
    @test J.html_div("dn","ct") == "<div class=\"dn\">ct</div>"
    @test J.html_img("src", "alt") == "<img src=\"src\" alt=\"alt\">"
    @test J.html_code("code") == "<pre><code class=\"plaintext\">code</code></pre>"
    @test J.html_code("code", "lang") == "<pre><code class=\"language-lang\">code</code></pre>"
    @test J.html_err("blah") == "<p><span style=\"color:red;\">// blah //</span></p>"
end

@testset "misc-html 2" begin
   h = "<div class=\"foo\">blah</div>"
   @test !J.is_html_escaped(h)
   @test J.html_code(h, "html") == """<pre><code class="language-html">&lt;div class&#61;&quot;foo&quot;&gt;blah&lt;/div&gt;</code></pre>"""
   he = Markdown.htmlesc(h)
   @test J.is_html_escaped(he)
   @test J.html_code(h, "html") == J.html_code(h, "html")
end

@testset "html_skip_hidden" begin
    c = """
        a=5
        b=7
        """
    @test J.html_skip_hidden(c, "foo") == c
    c = """
        #hideall
        a=5
        b=7
        """
    @test J.html_skip_hidden(c, "julia") == ""
    c = """
        a=5 #hide
        b=7
        """
    @test J.html_skip_hidden(c, "julia") == "b=7"
end

@testset "html_code" begin
    c = """
        using Random
        Random.seed!(555) # hide
        a = randn()
        b = a + 5
        """
    @test J.html_code(c, "julia") ==
        """<pre><code class="language-julia">using Random
        a = randn()
        b = a + 5</code></pre>"""
end
