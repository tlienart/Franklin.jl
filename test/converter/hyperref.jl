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

    J.def_GLOB_VARS!()
    J.def_GLOB_LXDEFS!()

    m, _ = J.convert_md(st, collect(values(J.JD_GLOB_LXDEFS)))

    h1 = J.refstring("eq 1")
    h2 = J.refstring("amari98b")
    h3 = J.refstring("bardenet17")

    @test haskey(J.JD_LOC_EQDICT,     h1)
    @test haskey(J.JD_LOC_BIBREFDICT, h2)
    @test haskey(J.JD_LOC_BIBREFDICT, h3)

    @test J.JD_LOC_EQDICT[h1]     == 1 # first equation
    @test J.JD_LOC_BIBREFDICT[h2] == "Amari and Douglas., 1998"
    @test J.JD_LOC_BIBREFDICT[h3] == "Bardenet et al., 2017"

    h = J.convert_html(m, J.JD_VAR_TYPE())

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
    m, _ = J.convert_md(st, collect(values(J.JD_GLOB_LXDEFS)))

    @test J.JD_LOC_EQDICT[J.JD_LOC_EQDICT_COUNTER] == 3
    @test J.JD_LOC_EQDICT[J.refstring("eq:a trivial one")] == 2
    @test J.JD_LOC_EQDICT[J.refstring("beyond hope")] == 3

    h1 = J.refstring("eq:a trivial one")
    h2 = J.refstring("beyond hope")

    m == "<p>Then something like  \$\$\\begin{array}{c}  \\mathbb E\\left[ f(X)\\right] \\in \\mathbb R &\\text{if}& f:\\mathbb R\\maptso\\mathbb R\\end{array}\$\$ and then  <a id=\"$h1\"></a>\$\$\\begin{array}{c}  1+1 &=&2 \\end{array}\$\$ but further  <a id=\"$h2\"></a>\$\$\\begin{array}{c}  1 &=& 1 \\end{array}\$\$ and finally a  <span class=\"eqref)\">({{href EQR $h1}})</span> and maybe  <span class=\"eqref)\">({{href EQR $h2}})</span>.</p>\n"
end


@testset "Input" begin
    #
    # check_input_fname
    #
    script1 = joinpath(J.JD_PATHS[:scripts], "script1.jl")
    write(script1, "1+1")
    @test J.check_input_fname("script1.jl") == script1
    @test_throws ArgumentError J.check_input_fname("script2.jl")

    #
    # resolve_input_hlcode
    #
    r = J.resolve_input_hlcode("script1.jl", "julia", use_hl=false)
    r2 = J.resolve_input_othercode("script1.jl", "julia")
    @test r == "<pre><code class=\"language-julia\">1+1\n</code></pre>"
    @test r2 == "<pre><code class=\"language-julia\">1+1</code></pre>"

    #
    # resolve_input_plainoutput
    #
    plain1 = joinpath(J.JD_PATHS[:scripts], "output", "script1.zog")
    write(plain1, "2")

    r = J.resolve_input_plainoutput("script1.jl")
    @test r == "<pre><code>2</code></pre>"
end
