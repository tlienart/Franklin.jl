@testset "latex-wspace" begin
    s = raw"""
    \newcommand{\hello}{hello}
    A\hello B
    """ |> jd2html_td
    @test isapproxstr(s, "<p>Ahello B</p>")
    s = raw"""
    \newcommand{\eqa}[1]{\begin{eqnarray}#1\end{eqnarray}}
    A\eqa{B}C
    \eqa{
        D
    }E
    """ |> jd2html_td
    @test isapproxstr(s, raw"""
            <p>
            A\[\begin{array}{c} B\end{array}\]C
            \[\begin{array}{c} D\end{array}\]E
            </p>""")

    s = raw"""
    \newcommand{\eqa}[1]{\begin{eqnarray}#1\end{eqnarray}}
    \eqa{A\\
        D
    }E
    """ |> jd2html_td
    @test isapproxstr(s, raw"""
        \[\begin{array}{c} A\\
        D\end{array}\]E
        """)
    s = raw"""
    @def indented_code = false
    \newcommand{\eqa}[1]{\begin{eqnarray}#1\end{eqnarray}}
    \eqa{A\\
        D}E""" |> jd2html_td
    @test isapproxstr(s, raw"""
        \[\begin{array}{c} A\\
        D\end{array}\]E
           """)
end

@testset "latex-wspmath" begin
    s = raw"""
    \newcommand{\esp}{\quad\!\!}
    $$A\esp=B$$
    """ |> jd2html_td
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
    """ |> jd2html_td
    @test isapproxstr(s, """<p>A <pre><code class="language-julia">C\n    B\n        E\nD</code></pre></p>\n""")
end
