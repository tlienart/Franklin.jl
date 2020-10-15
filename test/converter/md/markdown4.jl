@testset "latex-wspace" begin
    s = raw"""
        \newcommand{\hello}{hello}
        A\hello B
        """ |> fd2html_td
    @test isapproxstr(s, "<p>Ahello B</p>")
    s = raw"""
        \newcommand{\eqa}[1]{\begin{eqnarray}#1\end{eqnarray}}
        A\eqa{B}C
        \eqa{
            D
        }E
        """ |> fd2html_td
    @test isapproxstr(s, raw"""
            <p>
            A\[\begin{array}{rcl} B\end{array}\]C
            \[\begin{array}{rcl} D\end{array}\]E
            </p>""")

    s = raw"""
    \newcommand{\eqa}[1]{\begin{eqnarray}#1\end{eqnarray}}

    \eqa{A\\
        D
    }

    E
    """ |> fd2html_td
    @test isapproxstr(s, raw"""
        \[\begin{array}{rcl} A\\
        D\end{array}\]
        <p>E</p>
        """)

    s = raw"""
    @def indented_code = false
    \newcommand{\eqa}[1]{\begin{eqnarray}#1\end{eqnarray}}

    \eqa{A\\
        D}

    E""" |> fd2html_td
    @test isapproxstr(s, raw"""
        \[\begin{array}{rcl} A\\
        D\end{array}\]
        <p>E</p>
           """)
end

@testset "latex-wspmath" begin
    s = raw"""
    \newcommand{\esp}{\quad\!\!}
    $$A\esp=B$$
    """ |> fd2html_td
    @test isapproxstr(s, raw"\[A\quad\!\!=B\]")
end

@testset "code-wspace" begin
    s = raw"""
    A
    ```
    C
        B
            E
    D
    ```
    """ |> fd2html_td
    @test isapproxstr(s, """<p>A</p> <pre><code class="language-julia">C\n    B\n        E\nD</code></pre>""")
end

@testset "auto html esc" begin
    s = raw"""
    Blah

    ```html
    <div class="foo">Blah</div>
    ```

    End
    """ |> fd2html_td
    @test isapproxstr(s, """
        <p>
        Blah</p>
        <pre><code class="language-html">&lt;div class&#61;&quot;foo&quot;&gt;Blah&lt;/div&gt;</code></pre>
        <p>End</p>""")
end
