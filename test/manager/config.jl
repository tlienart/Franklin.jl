# additional tests for config

foofig(p, s) = (write(joinpath(p, "src", "config.md"), s); F.process_config())

@testset "config" begin
    p = joinpath(D, "..", "__tst_config")
    isdir(p) && rm(p; recursive=true, force=true)
    mkdir(p); cd(p);
    F.FOLDER_PATH[] = pwd()
    F.set_paths!()
    mkdir(joinpath(p, "src"))
    # ================================
    # asssignments go to GLOBAL
    foofig(p, raw"""
        @def var = 5
        """)
    @test haskey(F.GLOBAL_VARS, "var")
    @test F.GLOBAL_VARS["var"][1] == 5

    # lxdefs go to GLOBAL
    foofig(p, raw"""
        \newcommand{\hello}{goodbye}
        """)
    @test haskey(F.GLOBAL_LXDEFS, "\\hello")
    @test F.GLOBAL_LXDEFS["\\hello"].def == "goodbye"

    # combination of lxdefs
    foofig(p, raw"""
        \newcommand{\hello}{goodbye}
        \newcommand{\hellob}{\hello}
        \newcommand{\helloc}{\hellob}
        """)

    @test F.GLOBAL_LXDEFS["\\hello"].from < F.GLOBAL_LXDEFS["\\hello"].to <
          F.GLOBAL_LXDEFS["\\hellob"].from < F.GLOBAL_LXDEFS["\\hellob"].to <
          F.GLOBAL_LXDEFS["\\helloc"].from < F.GLOBAL_LXDEFS["\\helloc"].to

    @test fd2html(raw"""\helloc"""; dir=p, internal=true) == "goodbye"

    # ================================
    # go back and cleanup
    cd(R); rm(p; recursive=true, force=true)
end
