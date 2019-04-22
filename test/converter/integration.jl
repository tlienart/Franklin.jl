# This set of tests directly uses the high-level `convert` functions
# And checks the behaviour is as expected.

J.def_GLOB_LXDEFS!()
cmd = st -> J.convert_md(st, collect(values(J.JD_GLOB_LXDEFS)))
chtml = t -> J.convert_html(t...)
conv = st -> st |> cmd |> chtml

@testset "∫ newcom" begin
    st = raw"""
        \newcommand{ \coma }[ 1]{hello #1}
        \newcommand{ \comb} [2 ]{\coma{#1}, goodbye #1, #2!}
        Then \comb{auth1}{auth2}.
        """ * J.EOS
    @test st |> conv == "<p>Then hello   auth1, goodbye  auth1,  auth2&#33;.</p>\n"
end

@testset "∫ math" begin
    st = raw"""
        \newcommand{\E}[1]{\mathbb E\left[#1\right]}
        \newcommand{\eqa}[1]{\begin{eqnarray}#1\end{eqnarray}}
        \newcommand{\R}{\mathbb R}
        Then something like
        \eqa{ \E{f(X)} \in \R &\text{if}& f:\R\maptso\R }
        """ * J.EOS
    @test st |> conv == "<p>Then something like \\[\\begin{array}{c}  \\mathbb E\\left[ f(X)\\right] \\in \\mathbb R &\\text{if}& f:\\mathbb R\\maptso\\mathbb R \\end{array}\\]</p>\n"
end


@testset "∫ re-com" begin # see #36
    st = raw"""
        \newcommand{\com}[1]{⭒!#1⭒}
        \com{A}
        \newcommand{\com}[1]{◲!#1◲}
        \com{A}
        """ * J.EOS
    @test st |> conv == "⭒A⭒\n◲A◲"
end

@testset "∫ div" begin # see #74
    st = raw"""
        Etc and `~~~` but hey.
        @@dd but `x` and `y`? @@
        done
        """ * JuDoc.EOS
    @test st |> conv == "<p>Etc and <code>~~~</code> but hey. <div class=\"dd\">but <code>x</code> and <code>y</code>? </div>\n done</p>\n"
end

@testset "∫ code-l" begin
    st = raw"""
        Some code
        ```julia
        struct P
            x::Real
        end
        ```
        done
        """ * JuDoc.EOS
    @test st |> conv == "<p>Some code <pre><code class=julia>struct P\n    x::Real\nend\n</code></pre> done</p>\n"
end

@testset "∫ math-br" begin # see #73
    st = raw"""
        \newcommand{\R}{\mathbb R}
        $$
            \min_{x\in \R^n} \quad f(x)+i_C(x).
        $$
        """ * J.EOS
    @test st |> conv == "\\[\n    \\min_{x\\in \\mathbb R^n} \\quad f(x)+i_C(x).\n\\]"
end

@testset "∫ insert" begin # see also #65
    st = raw"""
        \newcommand{\com}[1]{⭒!#1⭒}
        abc\com{A}\com{B}def.
        """ * J.EOS
    @test st |> conv == "<p>abc⭒A⭒⭒B⭒def.</p>\n"

    st = raw"""
        \newcommand{\com}[1]{⭒!#1⭒}
        abc

        \com{A}\com{B}

        def.
        """ * J.EOS
    @test st |> conv == "<p>abc</p>\n⭒A⭒⭒B⭒\n<p>def.</p>\n"

    st = raw"""
        \newcommand{\com}[1]{⭒!#1⭒}
        abc

        \com{A}

        def.
        """ * J.EOS
    @test st |> conv == "<p>abc</p>\n⭒A⭒\n<p>def.</p>\n"

    st = raw"""
        \newcommand{\com}[1]{†!#1†}
        blah \com{a}
        * \com{aaa} tt
        * ss \com{bbb}
        """ * J.EOS
    @test st |> conv == "<p>blah †a†\n<ul>\n<li><p>†aaa† tt</p>\n</li>\n<li><p>ss †bbb†</p>\n</li>\n</ul>\n"
end

@testset "∫ br-rge" begin # see #70
    st = raw"""
           \newcommand{\scal}[1]{\left\langle#1\right\rangle}
           \newcommand{\E}{\mathbb E}
           exhibit A
           $\scal{\mu, \nu} = \E[X]$
           exhibit B
           $\E[X] = \scal{\mu, \nu}$
           end.""" * J.EOS
    @test st |> conv == "<p>exhibit A \\(\\left\\langle \\mu, \\nu\\right\\rangle = \\mathbb E[X]\\) exhibit B \\(\\mathbb E[X] = \\left\\langle \\mu, \\nu\\right\\rangle\\) end.</p>\n"
end

@testset "∫ cond" begin
    stv(var1, var2) = """
        @def var1 = $var1
        @def var2 = $var2
        start
        ~~~
        {{ if var1 }} targ1 {{ else if var2 }} targ2 {{ else }} targ3 {{ end }}
        ~~~
        done
        """ * J.EOS
    @test stv(true, true)   |> conv == "<p>start \n targ1 \n done</p>\n"
    @test stv(false, true)  |> conv == "<p>start \n targ2 \n done</p>\n"
    @test stv(false, false) |> conv == "<p>start \n targ3 \n done</p>\n"
end

@testset "∫ recurs" begin # see #97
    st = raw"""
        | A | B |
        | :---: | :---: |
        | C | D |
        """ * J.EOS

    @test st |> conv == "<table><tr><th>A</th><th>B</th></tr><tr><td>C</td><td>D</td></tr></table>\n"
    @test J.convert_md(st, isrecursive=true) |> chtml == st |> conv

    st = raw"""
        @@emptydiv
        @@emptycore
        @@
        @@
        """ * J.EOS
    st |> conv == "<div class=\"emptydiv\"><div class=\"emptycore\"></div>\n</div>\n"
end
