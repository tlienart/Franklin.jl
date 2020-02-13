# additional tests for config
fs2()

foofig(s) = (write(joinpath(td, "config.md"), s); F.process_config())

@testset "config" begin
    # ================================
    # asssignments go to GLOBAL
    foofig(raw"""
        @def var = 5
        """)
    @test haskey(F.GLOBAL_VARS, "var")
    @test F.GLOBAL_VARS["var"][1] == 5

    # lxdefs go to GLOBAL
    foofig(raw"""
        \newcommand{\hello}{goodbye}
        """)
    @test haskey(F.GLOBAL_LXDEFS, "\\hello")
    @test F.GLOBAL_LXDEFS["\\hello"].def == "goodbye"

    # combination of lxdefs
    foofig(raw"""
        \newcommand{\hello}{goodbye}
        \newcommand{\hellob}{\hello}
        \newcommand{\helloc}{\hellob}
        """)

    @test F.GLOBAL_LXDEFS["\\hello"].from < F.GLOBAL_LXDEFS["\\hello"].to <
          F.GLOBAL_LXDEFS["\\hellob"].from < F.GLOBAL_LXDEFS["\\hellob"].to <
          F.GLOBAL_LXDEFS["\\helloc"].from < F.GLOBAL_LXDEFS["\\helloc"].to

    @test fd2html(raw"""\helloc"""; dir=td, internal=true) == "goodbye"
end
