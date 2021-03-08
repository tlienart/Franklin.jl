@testset "Conv-lx" begin
    cd(td)
    # Exception instead of ArgumentError as may fail with system error
    @test_throws Exception F.check_input_rpath("aldjfk")
end

@testset "Conv-html" begin
    @test_throws F.HTMLFunctionError F.convert_html("{{insert bb cc}}")
    @test_throws F.HTMLFunctionError F.convert_html("{{href aa}}")

    global r = ""; s = @capture_out begin
        global r
        r = F.convert_html("{{href aa bb}}")
    end
    @test r == "<b>??</b>"
    @test occursin("Unknown reference dictionary 'aa'", s)

    @test_throws F.HTMLBlockError F.convert_html("{{if asdf}}{{end}}")
    @test_throws F.HTMLBlockError F.convert_html("{{if asdf}}")
    @test_throws F.HTMLBlockError F.convert_html("{{isdef asdf}}")
    @test_throws F.HTMLBlockError F.convert_html("{{ispage asdf}}")
end

@testset "Conv-md" begin
    s = """
        @def blah
        """
    global r = ""; s = @capture_out begin
        global r
        r = s |> fd2html_td
    end
    @test r == ""
    @test occursin("Delimiters for an '@def ...'", s)

    s = """
        Blah
        [^1]: hello
        """ |> fd2html_td
    @test isapproxstr(s, "<p>Blah </p>")
end

@testset "Franklin" begin
    cd(td); mkpath("foo"); cd("foo"); write("config.md","")
    @test_throws ArgumentError serve(single=true)
    cd(td)
end

@testset "RSS" begin
    F.set_var!(F.GLOBAL_VARS, "website_descr", "")
    F.RSS_DICT["hello"] = (F.RSSItem("","","","","","","","",Date(1)), String[])
    global r = ""; s = @capture_out begin
        global r
        r = F.rss_generator()
    end
    @test r === nothing
    @test occursin("RSS items were found but", s)
end


@testset "parser-lx" begin
    s = raw"""
        \newcommand{hello}{hello}
        """
    @test_throws F.LxDefError (s |> fd2html)
    s = raw"""
        \foo
        """
    @test_throws F.LxObjError (s |> fd2html)
    s = raw"""
        \newcommand{\foo}[2]{hello #1 #2}
        \foo{a} {}
        """
    @test_throws F.LxObjError (s |> fd2html)
end

@testset "ocblocks" begin
    s = raw"""
        @@foo
        """
    @test_throws F.OCBlockError (s |> fd2html)
end

@testset "tofrom" begin
    s = "jμΛΙα"
    @test F.from(s) == 1
    @test F.to(s) == lastindex(s)
end


@testset "{{toc}}" begin
    s = """
        ~~~
        {{toc 1 2}}
        ~~~
        # Hello
        ## Goodbye
        """ |> fd2html_td
    @test isapproxstr(s, raw"""
        <div class="franklin-toc"><ol><li><a href="#hello">Hello</a><ol><li><a href="#goodbye">Goodbye</a></li></ol></li></ol></div>
        <h1 id="hello"><a href="#hello" class="header-anchor">Hello</a></h1>
        <h2 id="goodbye"><a href="#goodbye" class="header-anchor">Goodbye</a></h2>""")
end
