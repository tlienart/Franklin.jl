J.JD_PATHS[:scripts] = joinpath(dirname(dirname(pathof(JuDoc))), "test", "_dummies", "scripts")

@testset "LX input" begin
    st = raw"""
        Some string
        \input{julia}{s1.jl}
        Then maybe
        \input{output:plain}{s1.jl}
        Finally img:
        \input{plot:a}{s1.jl}
        done.
        """ * J.EOS;

    J.def_GLOB_VARS!()
    J.def_GLOB_LXDEFS!()

    m, _ = J.convert_md(st, collect(values(J.JD_GLOB_LXDEFS)))
    h = J.convert_html(m, J.JD_VAR_TYPE())

    @test occursin("Some string <pre><code class=\"language-julia\">$(read(joinpath(J.JD_PATHS[:scripts], "s1.jl"), String))</code></pre>", h)
    @test occursin("Then maybe <pre><code>$(read(joinpath(J.JD_PATHS[:scripts], "output", "s1.txt"), String))</code></pre>", h)
    @test occursin("Finally img: <img src=\"assets/scripts/output/s1a.png\" id=\"judoc-out-plot\"/> done.", h)
end
