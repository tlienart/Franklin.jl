@testset "Conv-lx" begin
    cd(td)
    # Exception instead of ArgumentError as may fail with system error
    @test_throws Exception J.check_input_rpath("aldjfk")
end

@testset "Conv-html" begin
    @test_throws J.HTMLFunctionError J.convert_html("{{fill bb cc}}", J.PageVars())
    @test_throws J.HTMLFunctionError J.convert_html("{{insert bb cc}}", J.PageVars())
    @test_throws J.HTMLFunctionError J.convert_html("{{href aa}}", J.PageVars())
    @test (@test_logs (:warn, "Unknown dictionary name aa in {{href ...}}. Ignoring") J.convert_html("{{href aa bb}}", J.PageVars())) == "<b>??</b>"
    @test_throws J.HTMLBlockError J.convert_html("{{if asdf}}{{end}}", J.PageVars())
    @test_throws J.HTMLBlockError J.convert_html("{{if asdf}}", J.PageVars())
    @test_throws J.HTMLBlockError J.convert_html("{{isdef asdf}}", J.PageVars())
    @test_throws J.HTMLBlockError J.convert_html("{{ispage asdf}}", J.PageVars())
end

@testset "Conv-md" begin
    s = """
        @def blah
        """
    @test (@test_logs (:warn, "Found delimiters for an @def environment but it didn't have the right @def var = ... format. Verify (ignoring for now).") (s |> jd2html_td)) == ""

    s = """
        Blah
        [^1]: hello
        """ |> jd2html_td
    @test isapproxstr(s, "<p>Blah </p>")
end

@testset "Judoc" begin
    cd(td); mkpath("foo"); cd("foo");
    @test_throws ArgumentError serve(single=true)
    cd(td)
end

@testset "RSS" begin
    J.set_var!(J.GLOBAL_PAGE_VARS, "website_descr", "")
    J.RSS_DICT["hello"] = J.RSSItem("","","","","","","",Date(1))
    @test (@test_logs (:warn, """
              I found RSS items but the RSS feed is not properly described:
              at least one of the following variables has not been defined in
              your config.md: `website_title`, `website_descr`, `website_url`.
              The feed will not be (re)generated.""") J.rss_generator()) === nothing
end


@testset "parser-lx" begin
    s = raw"""
        \newcommand{hello}{hello}
        """
    @test_throws J.LxDefError (s |> jd2html)
    s = raw"""
        \foo
        """
    @test_throws J.LxComError (s |> jd2html)
    s = raw"""
        \newcommand{\foo}[2]{hello #1 #2}
        \foo{a} {}
        """
    @test_throws J.LxComError (s |> jd2html)
end

@testset "ocblocks" begin
    s = raw"""
        @@foo
        """
    @test_throws J.OCBlockError (s |> jd2html)
end
