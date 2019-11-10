# additional tests for config

foofig(p, s) = (write(joinpath(p, "src", "config.md"), s); J.process_config())

@testset "config" begin
    p = joinpath(D, "..", "__tst_config")
    isdir(p) && rm(p; recursive=true, force=true)
    mkdir(p); cd(p);
    J.FOLDER_PATH[] = pwd()
    J.set_paths!()
    mkdir(joinpath(p, "src"))
    # ================================
    # asssignments go to GLOBAL
    foofig(p, raw"""
    @def var = 5
    """)
    @test haskey(J.GLOBAL_PAGE_VARS, "var")
    @test J.GLOBAL_PAGE_VARS["var"][1] == 5

    # lxdefs go to GLOBAL
    foofig(p, raw"""
    \newcommand{\hello}{goodbye}
    """)
    @test haskey(J.GLOBAL_LXDEFS, "\\hello")
    @test J.GLOBAL_LXDEFS["\\hello"].def == "goodbye"

    # combination of lxdefs
    foofig(p, raw"""
    \newcommand{\hello}{goodbye}
    \newcommand{\hellob}{\hello}
    \newcommand{\helloc}{\hellob}
    """)

    @test J.GLOBAL_LXDEFS["\\hello"].from < J.GLOBAL_LXDEFS["\\hello"].to <
          J.GLOBAL_LXDEFS["\\hellob"].from < J.GLOBAL_LXDEFS["\\hellob"].to <
          J.GLOBAL_LXDEFS["\\helloc"].from < J.GLOBAL_LXDEFS["\\helloc"].to

    @test jd2html(raw"""\helloc"""; dir=p, internal=true) == "goodbye"

    # ================================
    # go back and cleanup
    cd(R); rm(p; recursive=true, force=true)
end
