@testset "Hyperref" begin
    st = raw"""
       Some string
       $$ x = x \label{eq 1}$$
       then as per \citet{amari98b} also this \citep{bardenet17} and
       \cite{amari98b, bardenet17}
       Reference to equation: \eqref{eq 1}.

       Then maybe some text etc.

       * \biblabel{amari98b}{Amari and Douglas., 1998} **Amari** and **Douglas**: *Why Natural Gradient*, 1998.
       * \biblabel{bardenet17}{Bardenet et al., 2017} **Bardenet**, **Doucet** and **Holmes**: *On Markov Chain Monte Carlo Methods for Tall Data*, 2017.
    """ * J.EOS;

    J.def_GLOBAL_PAGE_VARS!()
    J.def_GLOBAL_LXDEFS!()

    m, _ = J.convert_md(st, collect(values(J.GLOBAL_LXDEFS)))

    h1 = J.refstring("eq 1")
    h2 = J.refstring("amari98b")
    h3 = J.refstring("bardenet17")

    @test haskey(J.PAGE_EQREFS,  h1)
    @test haskey(J.PAGE_BIBREFS, h2)
    @test haskey(J.PAGE_BIBREFS, h3)

    @test J.PAGE_EQREFS[h1]  == 1 # first equation
    @test J.PAGE_BIBREFS[h2] == "Amari and Douglas., 1998"
    @test J.PAGE_BIBREFS[h3] == "Bardenet et al., 2017"

    h = J.convert_html(m, J.PageVars())

    @test occursin("<a id=\"$h1\"></a>\\[ x = x \\]", h)
    @test occursin("<li><p><a id=\"$h2\"></a> <strong>Amari</strong> and <strong>Douglas</strong>: <em>Why Natural Gradient</em>, 1998.</p>\n</li>", h)
    @test occursin("<li><p><a id=\"$h3\"></a> <strong>Bardenet</strong>, <strong>Doucet</strong> and <strong>Holmes</strong>: <em>On Markov Chain Monte Carlo Methods for Tall Data</em>, 2017.</p>\n</li>", h)

    @test occursin("<span class=\"eqref\">(<a href=\"#$h1\">1</a>)</span>", h)
    @test occursin("<span class=\"bibref\"><a href=\"#$h2\">Amari and Douglas., 1998</a></span>", h)
    @test occursin("<span class=\"bibref\">(<a href=\"#$h3\">Bardenet et al., 2017</a>)</span>", h)
    @test occursin("<span class=\"bibref\"><a href=\"#$h2\">Amari and Douglas., 1998</a>, <a href=\"#$h3\">Bardenet et al., 2017</a></span>", h)
end


@testset "Eqref" begin
    st = raw"""
        \newcommand{\E}[1]{\mathbb E\left[#1\right]}
        \newcommand{\eqa}[1]{\begin{eqnarray}#1\end{eqnarray}}
        \newcommand{\R}{\mathbb R}
        Then something like
        \eqa{ \E{f(X)} \in \R &\text{if}& f:\R\maptso\R}
        and then
        \eqa{ 1+1 &=& 2 \label{eq:a trivial one}}
        but further
        \eqa{ 1 &=& 1 \label{beyond hope}}
        and finally a \eqref{eq:a trivial one} and maybe \eqref{beyond hope}.
        """ * J.EOS
    m, _ = J.convert_md(st, collect(values(J.GLOBAL_LXDEFS)))

    @test J.PAGE_EQREFS[J.PAGE_EQREFS_COUNTER] == 3
    @test J.PAGE_EQREFS[J.refstring("eq:a trivial one")] == 2
    @test J.PAGE_EQREFS[J.refstring("beyond hope")] == 3

    h1 = J.refstring("eq:a trivial one")
    h2 = J.refstring("beyond hope")

    m == "<p>Then something like  \$\$\\begin{array}{c}  \\mathbb E\\left[ f(X)\\right] \\in \\mathbb R &\\text{if}& f:\\mathbb R\\maptso\\mathbb R\\end{array}\$\$ and then  <a id=\"$h1\"></a>\$\$\\begin{array}{c}  1+1 &=&2 \\end{array}\$\$ but further  <a id=\"$h2\"></a>\$\$\\begin{array}{c}  1 &=& 1 \\end{array}\$\$ and finally a  <span class=\"eqref)\">({{href EQR $h1}})</span> and maybe  <span class=\"eqref)\">({{href EQR $h2}})</span>.</p>\n"
end
