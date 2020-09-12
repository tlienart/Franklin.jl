@testset "parse fenced" begin
    s = """
        A
        ```julia
        using Random
        Random.seed!(55) # hide
        a = randn()
        ```
        B
        """
    css = SubString(s, 3, 63)
    lang, rpath, code = F.parse_fenced_block(css)
    @test lang == "julia"
    @test rpath === nothing
    @test code ==
        """using Random
        Random.seed!(55) # hide
        a = randn()"""
    s = """
        A
        ```julia:ex1
        using Random
        Random.seed!(55) # hide
        a = randn()
        ```
        B
        """
    css = SubString(s, 3, 67)
    lang, rpath, code = F.parse_fenced_block(css)
    @test lang == "julia"
    @test rpath == "ex1"
    @test code ==
        """using Random
        Random.seed!(55) # hide
        a = randn()"""

    # more cases to test REGEX_CODE
    rx3 = F.CODE_3_PAT
    rx5 = F.CODE_5_PAT

    s = "```julia:ex1 A```"
    m = match(rx3, s)
    @test m.captures[2] == ":ex1"
    s = "```julia:ex1_b2 A```"
    m = match(rx3, s)
    @test m.captures[2] == ":ex1_b2"
    s = "```julia:ex1_b2-33 A```"
    m = match(rx3, s)
    @test m.captures[2] == ":ex1_b2-33"
    s = "```julia:./ex1/v1_b2 A```"
    m = match(rx3, s)
    @test m.captures[2] == ":./ex1/v1_b2"
    s = "```julia:./ex1/v1_b2.f99 A```"
    m = match(rx3, s)
    @test m.captures[2] == ":./ex1/v1_b2.f99"

    s = "`````julia:./ex1/v1_b2.f99 A`````"
    m = match(rx5, s)
    @test m.captures[2] == ":./ex1/v1_b2.f99"
end

@testset "resolve code" begin
    # no eval
    c = SubString(
        """```julia
        a = 5
        b = 7
        ```""")
    @test F.resolve_code_block(c) ==
        """<pre><code class="language-julia">$(F.htmlesc("""a = 5
        b = 7"""))</code></pre>"""
    # not julia code
    c = SubString(
        """```python:ex
        a = 5
        b = 7
        ```""")

    s = @capture_out F.resolve_code_block(c)
    @test occursin("Evaluation of non-Julia code", s)

    # should eval
    bak = pwd()
    tmp = mktempdir()
    begin
        cd(tmp)
        set_curpath("index.md")
        F.FOLDER_PATH[] = tmp
        F.def_LOCAL_VARS!()
        F.set_paths!()
        c = SubString(
            """```julia:ex
            a = 5
            b = 7
            ```""")
        r = F.resolve_code_block(c)
        @test r ==
            """<pre><code class="language-julia">$(F.htmlesc("""a = 5
            b = 7"""))</code></pre>"""
    end
    cd(bak)
end
