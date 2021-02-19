# see issue #151
@testset "HTML escape" begin
    st = read(joinpath(D, "151.md"), String)
    @test isapproxstr(st |> conv,
            """<pre><code class=\"language-julia\">
            add OhMyREPL#master
            </code></pre>
            <p>AAA</p>

            <pre><code class=\"language-julia\">
            \"\"\"
                bar(x[, y])

            BBB

            # Examples
            ```jldoctest
            D
            ```
            \"\"\"
            function bar(x, y)
                ...
            end
            </code></pre>

            <p>For complex functions with multiple arguments use a argument list, also if there are many keyword arguments use <code>&lt;keyword arguments&gt;</code>:</p>

            <pre><code class=\"language-julia\">
            \"\"\"
                matdiag(diag, nr, nc; &ltkeyword arguments&gt)

            Create Matrix with number `vdiag` on the super- or subdiagonals and `vndiag`
            in the rest.

            # Arguments
            - `diag::Number`: `Number` to write into created super- or subdiagonal

            # Examples
            ```jldoctest
            julia> matdiag(true, 5, 5, sr=2, ec=3)
            ```
            \"\"\"
            function matdiag(diag::Number, nr::Integer, nc::Integer;)
                ...
            end
            </code></pre>""")
end


# see issue #182
@testset "Code blocks" begin
    st = read(joinpath(D, "182.md"), String)
    @test isapproxstr(st |> conv, """
            <p>Code block:</p>

            The <em>average</em> temperature is <strong>19.5°C</strong>.

            <p>The end.</p>
            """)
end

@testset "Table" begin
    fs()
    st = """
        @def fd_rpath = "pages/pg1.html"
        A

        ### Title

        No. | Graph | Vertices | Edges
        :---: | :---------: | :------------: | :-----------------:
        1 | Twitter Social Circles | 81,306 | 1,342,310
        2 | Astro-Physics Collaboration | 17,903 | 197,031
        3 | Facebook Social Circles | 4,039 | 88,234

        C
        """

    if VERSION >= v"1.4.0-"
        @test isapproxstr(st |> seval, raw"""<p>A</p>
            <h3 id="title"><a href="#title" class="header-anchor">Title</a></h3>

            <table><tr><th align="center">No.</th><th align="center">Graph</th><th align="center">Vertices</th><th align="center">Edges</th></tr><tr><td align="center">1</td><td align="center">Twitter Social Circles</td><td align="center">81,306</td><td align="center">1,342,310</td></tr><tr><td align="center">2</td><td align="center">Astro-Physics Collaboration</td><td align="center">17,903</td><td align="center">197,031</td></tr><tr><td align="center">3</td><td align="center">Facebook Social Circles</td><td align="center">4,039</td><td align="center">88,234</td></tr></table>
            <p>C</p>""")
    end
end

@testset "Auto title" begin
    # if no title is set, then the first header is used
    s = raw"""
    # AAA
    etc
    ~~~{{fill title}}~~~
    """ |> fd2html_td
    @test isapproxstr(s, raw"""<h1 id="aaa"><a href="#aaa" class="header-anchor">AAA</a></h1>  <p>etc AAA</p>""")
end

@testset "i 430" begin
    s = raw"""
        Hello[^ö]

        [^ö]: world
        """ |> fd2html_td
    @test isapproxstr(s, """
        <p>Hello<sup id="fnref:ö"><a href="#fndef:ö" class="fnref">[1]</a></sup></p>
        <table class="fndef" id="fndef:ö">
          <tr>
            <td class="fndef-backref"><a href="#fnref:ö">[1]</a></td>
            <td class="fndef-content">world</td>
          </tr>
        </table>
        """)
end

@testset "i 419" begin
    F.set_var!(F.LOCAL_VARS, "hascode", false)
    F.set_var!(F.LOCAL_VARS, "hasmath", false)
    s = raw"""
        {{hasmath}} {{hascode}}
        $x = 5$
        """ |> fdi
    @test isapproxstr(s, "<p>true false \\(x = 5\\)</p>")
    F.set_var!(F.LOCAL_VARS, "hascode", false)
    F.set_var!(F.LOCAL_VARS, "hasmath", false)
    s = raw"""
        {{hasmath}} {{hascode}}
        ```r
        blah
        ```
        """ |> fdi
    @test isapproxstr(s, """
        <p>false true</p>
        <pre><code class=\"language-r\">blah</code></pre>
        """)
end
