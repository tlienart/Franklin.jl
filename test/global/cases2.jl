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
    J.CUR_PATH[] = "pages/pg1.html"
    st = """
        A

        ### Title

        No. | Graph | Vertices | Edges
        :---: | :---------: | :------------: | :-----------------:
        1 | Twitter Social Circles | 81,306 | 1,342,310
        2 | Astro-Physics Collaboration | 17,903 | 197,031
        3 | Facebook Social Circles | 4,039 | 88,234

        C
        """ * J.EOS

    @test isapproxstr(st |> seval, raw""" <p>A</p>
        <h3 id="title"><a href="/pub/pg1.html#title">Title</a></h3>

        <table>
          <tr>
            <th>No.</th><th>Graph</th><th>Vertices</th><th>Edges</th>
          </tr>
          <tr>
            <td>1</td><td>Twitter Social Circles</td><td>81,306</td><td>1,342,310</td>
          </tr>
          <tr>
            <td>2</td><td>Astro-Physics Collaboration</td><td>17,903</td><td>197,031</td>
          </tr>
          <tr>
            <td>3</td><td>Facebook Social Circles</td><td>4,039</td><td>88,234</td>
          </tr>
        </table>

        <p>C</p>
        """)
end
