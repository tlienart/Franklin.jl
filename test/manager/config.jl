# additional tests for config
fs()

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

    @test fd2html(raw"""\helloc"""; dir=td, internal=true) // "goodbye"
end

@testset "i381" begin
    foofig(raw"""
        @def tags = []
        """)

    s = """
        @def tags = ["tag1", "tag2"]

        ~~~
        {{for tag in tags}}
        {{fill tag}}
        {{end}}
        ~~~
        """ |> fd2html_td
    @test isapproxstr(s, "tag1 tag2")
end
