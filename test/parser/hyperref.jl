@testset "Hyperref" begin
    st = raw"""
       Some string
       $$ x = x \label{eq 1}$$
       then as per \citet{amari98b} also this \citep{bardenet17}.
       Reference to equation: \eqref{eq 1}.

       Then maybe some text etc.

       * \biblabel{amari98b}{Amari and Douglas., 1998} **Amari** and **Douglas**: *Why Natural Gradient*, 1998.
       * \biblabel{bardenet17}{Bardenet et al., 2017} **Bardenet**, **Doucet** and **Holmes**: *On Markov Chain Monte Carlo Methods for Tall Data*, 2017.
    """ * JuDoc.EOS;

    JuDoc.def_LOC_VARS()
    JuDoc.def_GLOB_VARS()
    JuDoc.def_GLOB_LXDEFS()

    m, _ = JuDoc.convert_md(st, collect(values(JuDoc.JD_GLOB_LXDEFS)))

    h1 = hash("eq 1")
    h2 = hash("amari98b")
    h3 = hash("bardenet17")

    @test haskey(JuDoc.JD_LOC_EQDICT, h1)
    @test haskey(JuDoc.JD_LOC_BIBREFDICT, h2)
    @test haskey(JuDoc.JD_LOC_BIBREFDICT, h3)

    @test JuDoc.JD_LOC_EQDICT[h1] == 1 # first equation
    @test JuDoc.JD_LOC_BIBREFDICT[h2] == "Amari and Douglas., 1998"
    @test JuDoc.JD_LOC_BIBREFDICT[h3] == "Bardenet et al., 2017"
end
