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
