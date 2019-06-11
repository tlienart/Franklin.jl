@testset "Generation and optimisation" begin
    cd(td)
    isdir("basic") && rm("basic", recursive=true, force=true)
    newsite("basic")
    serve(single=true)
    # ---------------
    @test all(isdir, ("assets", "css", "libs", "pub", "src"))
    @test all(isfile, ("index.html",
                 map(e->joinpath("pub", "menu$e.html"), 1:3)...,
                 map(e->joinpath("css", e), ("basic.css", "highlight.css", "judoc.css"))...,
                 )
              )
    # ---------------
    if JuDoc.JD_CAN_MINIFY
        presize1 = stat(joinpath("css", "basic.css")).size
        presize2 = stat("index.html").size
        optimize(prerender=false)
        @test stat(joinpath("css", "basic.css")).size < presize1
        @test stat("index.html").size < presize2
    end
    # ---------------
    # change the prepath
    index = read("index.html", String)
    @test occursin("=\"/css/basic.css", index)
    @test occursin("=\"/css/judoc.css", index)
    @test occursin("=\"/libs/highlight/github.min.css", index)
    @test occursin("=\"/libs/katex/katex.min.css", index)

    optimize(minify=false, prerender=false, prepath="prependme")
    index = read("index.html", String)
    @test occursin("=\"/prependme/css/basic.css", index)
    @test occursin("=\"/prependme/css/judoc.css", index)
    @test occursin("=\"/prependme/libs/highlight/github.min.css", index)
    @test occursin("=\"/prependme/libs/katex/katex.min.css", index)
end
