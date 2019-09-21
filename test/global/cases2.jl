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
    st |> seval

    st |> Markdown.parse
end
