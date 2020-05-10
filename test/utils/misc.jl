# This is a test file to make codecov happy, technically all of the
# tests here are already done / integrated within other tests.

@testset "strings" begin
    st = "blah"

    @test F.str(st) == "blah"

    sst = SubString("blahblah", 1:4)
    @test sst == "blah"
    @test F.str(sst) == "blahblah"

    sst = SubString("blah✅💕and etcσ⭒ but ∃⫙∀ done", 1:27)
    @test F.to(sst) == 27

    s = "aabccabcdefabcg"
    for m ∈ eachmatch(r"abc", s)
        @test s[F.matchrange(m)] == "abc"
    end
end

@testset "ocblock" begin
    st = "This is a block <!--comment--> and done"
    τ = F.find_tokens(st, F.MD_TOKENS, F.MD_1C_TOKENS)
    ocb = F.OCBlock(:COMMENT, (τ[1]=>τ[2]))
    @test F.otok(ocb) == τ[1]
    @test F.ctok(ocb) == τ[2]
end

@testset "isexactly" begin
    steps, b, λ = F.isexactly("<!--")
    @test steps == length("<!--") - 1 # minus start char
    @test b == false
    @test λ("<!--",false) == true
    @test λ("<--",false) == false

    steps, b, λ, = F.isexactly("\$", ('\$',))
    @test steps == 1
    @test b == true
    @test λ("\$\$",false) == true
    @test λ("\$a",false) == false
    @test λ("a\$",false) == false

    rs = "\$"
    steps, b, λ = F.isexactly(rs, ('\$',), false)
    @test steps == nextind(rs, prevind(rs, lastindex(rs)))
    @test b == true
    @test λ("\$\$",false) == false
    @test λ("\$a",false) == true
    @test λ("a\$",false) == false

    steps, b, λ = F.incrlook(isletter)
    @test steps == 0
    @test b == false
    @test λ('c') == true
    @test λ('[') == false
end

@testset "timeittook" begin
    start = time()
    sleep(0.5)

    d = mktempdir()
    f = joinpath(d, "a.txt")
    open(f, "w") do outf
        redirect_stdout(outf) do
            F.print_final("elapsing",start)
        end
    end
    r = read(f, String)
    m = match(r"\[done\s*(.*?)ms\]", r)
    @test parse(Float64, m.captures[1]) ≥ 500
end

@testset "refstring" begin
    @test F.refstring("aa  bb") == "aa_bb"
    @test F.refstring("aa <code>bb</code>") == "aa_bb"
    @test F.refstring("aa  bb !") == "aa_bb"
    @test F.refstring("aa-bb-!") == "aa-bb-"
    @test F.refstring("aa 🔺 bb") == "aa_bb"
    @test F.refstring("aaa 0 bb s:2  df") == "aaa_0_bb_s2_df"
    @test F.refstring("🔺🔺") == string(hash("🔺🔺"))
    @test F.refstring("blah&#33;") == "blah"
end

@testset "misc-html" begin
    λ = "blah/blah.ext"
    set_curpath("pages/cpB/blah.md")
    @test F.html_ahref(λ, 1) == "<a href=\"$λ\">1</a>"
    @test F.html_ahref(λ, "bb") == "<a href=\"$λ\">bb</a>"
    @test F.html_ahref_key("cc", "dd") == "<a href=\"#cc\">dd</a>"
    @test F.html_div("dn","ct") == "<div class=\"dn\">ct</div>"
    @test F.html_img("src", "alt") == "<img src=\"src\" alt=\"alt\">"
    @test F.html_code("code") == "<pre><code class=\"plaintext\">code</code></pre>"
    @test F.html_code("code", "lang") == "<pre><code class=\"language-lang\">code</code></pre>"
    @test F.html_err("blah") == "<p><span style=\"color:red;\">// blah //</span></p>"
end

@testset "misc-html 2" begin
   h = "<div class=\"foo\">blah</div>"
   @test !F.is_html_escaped(h)
   @test F.html_code(h, "html") == """<pre><code class="language-html">&lt;div class&#61;&quot;foo&quot;&gt;blah&lt;/div&gt;</code></pre>"""
   he = Markdown.htmlesc(h)
   @test F.is_html_escaped(he)
   @test F.html_code(h, "html") == F.html_code(h, "html")
end

@testset "match_url" begin
    @test F.match_url("index", "/index.html")
    @test F.match_url("index", "/index.html")
    @test F.match_url("index", "index.html")
    @test F.match_url("/index", "index.html")
    @test F.match_url("menu1", "/menu1/")
    @test F.match_url("menu1", "menu1/")
    @test F.match_url("menu1", "menu1")
    @test F.match_url("menu1", "/menu1/*")
end

@testset "check_type" begin
    @test F.check_type(Float64, (Real,))
    @test F.check_type(Float64, (Real, String))
    @test F.check_type(Int,     (Any,))
    @test !F.check_type(String, (Real,))
    @test F.check_type(Vector{Float64}, (Vector{Real},))
    @test F.check_type(Vector{String},  (Vector{Any},))
    @test !F.check_type(Vector{String}, (Matrix{Any},))
end

@testset "Date locales" begin
    s = raw"""
    @def date_format = "e, d u Y"
    @def date_months = ["janvier", "février", "mars", "avril", "mai", "juin",
                        "juillet", "août", "septembre", "octobre", "novembre",
                        "décembre"];
    @def date_shortmonths = ["janv","févr","mars","avril","mai","juin",
                                "juil","août","sept","oct","nov","déc"];
    @def date_days = ["lundi","mardi","mercredi","jeudi",
                        "vendredi","samedi","dimanche"];
    ```julia:ex1
    #hideall
    using Franklin, Dates
    println(Franklin.fd_date(DateTime("1996-01-01T12:30:00")))
    ```
    \textoutput{ex1}
    """ |> fd2html_td
    @test isapproxstr(s, "lun, 1 janv 1996") # auto short names

    s = raw"""
    @def date_format = "d u Y"
    @def date_months = ["janvier", "février", "mars", "avril", "mai", "juin",
                        "juillet", "août", "septembre", "octobre", "novembre",
                        "décembre"];
    ```julia:ex2
    #hideall
    using Franklin, Dates
    println(Franklin.fd_date(DateTime("1996-12-01T12:30:00")))
    ```
    \textoutput{ex2}
    """ |> fd2html_td
    @test isapproxstr(s, "1 déc 1996") # accents in short names

    s = raw"""
    @def date_format = "d u Y"
    @def date_shortmonths = ["janv","févr","mars","avril","mai","juin",
                                "juil","août","sept","oct","nov","déc"];
    ```julia:ex3
    #hideall
    using Franklin, Dates
    println(Franklin.fd_date(DateTime("1996-01-01T12:30:00")))
    ```
    \textoutput{ex3}
    """ |> fd2html_td
    @test isapproxstr(s, "1 janv 1996") # only short names defined

    s = raw"""
    @def date_format = "Y年ud日　E"
    @def date_months = ["1月", "2月", "3月", "4月", "5月", "6月",
                        "7月", "8月", "9月", "10月", "11月", "12月"];

    @def date_days = ["月曜日","火曜日","水曜日","木曜日",
                        "金曜日","土曜日","日曜日"];
    ```julia:ex4
    #hideall
    using Franklin, Dates
    println(Franklin.fd_date(DateTime("1996-01-01T12:30:00")))
    ```
    \textoutput{ex4}
    """ |> fd2html_td
    @test isapproxstr(s, "1996年1月1日　月曜日") # japanese and unicode
end

@testset "dict-inv" begin
    d = F.LittleDict(
        "blog/pg1" => ["aa", "bb", "cc"],
        "blog/pg2" => ["cc", "bb"],
        "blog/pg3" => ["aa", "ee"],
        )
    id = F.invert_dict(d)
    @test id isa F.LittleDict{String,Vector{String}}
    @test Set(collect(keys(id))) == Set(collect(vcat(values(d)...)))
    @test Set(collect(keys(d))) == Set(collect(vcat(values(id)...)))
    @test Set(id["aa"]) == Set(["blog/pg1", "blog/pg3"])
    @test Set(id["ee"]) == Set(["blog/pg3"])
end

@testset "get_url" begin
    fs2()

    @test get_url("foo") == "/foo/"
    @test get_url("foo/bar") == "/foo/bar/"
    @test get_url("index") == "/"
    @test get_url("foo/index") == "/foo/"
    @test get_url("foo.md") == "/foo/"
    @test get_url("foo/index.md") == "/foo/"
end
