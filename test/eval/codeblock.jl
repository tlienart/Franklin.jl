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
end

@testset "resolve code" begin
    # no eval
    c = SubString(
        """```julia
        a = 5
        b = 7
        ```""")
    @test F.resolve_code_block(c) ==
        """<pre><code class="language-julia">a = 5
        b = 7</code></pre>"""
    # not julia code
    c = SubString(
        """```python:ex
        a = 5
        b = 7
        ```""")
    @test @test_logs (:warn, "Evaluation of non-Julia code blocks is not yet supported.") F.resolve_code_block(c) ==
        """<pre><code class="language-python">a = 5
        b = 7</code></pre>"""

    # should eval
    bak = pwd()
    tmp = mktempdir()
    begin
        cd(tmp)
        F.FD_ENV[:CUR_PATH] = "index.md"
        F.FOLDER_PATH[] = tmp
        F.def_LOCAL_PAGE_VARS!()
        F.set_paths!()
        c = SubString(
            """```julia:ex
            a = 5
            b = 7
            ```""")
        r = F.resolve_code_block(c)
        @test r ==
            """<pre><code class="language-julia">a = 5
            b = 7</code></pre>"""
    end
    cd(bak)
end
