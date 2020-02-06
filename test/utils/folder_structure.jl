@testset "set_paths!" begin
    empty!(F.PATHS)
    F.FD_ENV[:STRUCTURE] = v"0.1"
    root = F.FOLDER_PATH[] = mktempdir()
    F.set_paths!()
    @test Set(keys(F.PATHS)) == Set([:folder, :src, :src_pages, :src_css, :src_html, :pub, :css, :libs, :assets, :literate])
    @test F.PATHS[:folder] == root
    @test F.PATHS[:src_pages] == joinpath(F.PATHS[:src], "pages")

    empty!(F.PATHS)
    F.FD_ENV[:STRUCTURE] = v"0.2"
    F.set_paths!()
    @test Set(keys(F.PATHS)) == Set([:folder, :assets, :css, :layout, :libs, :literate, :a_aux, :a_infra, :a_scripts, :a_literate, :site])
    @test F.PATHS[:folder]   == root
    @test F.PATHS[:site]     == joinpath(root, "__site")
    @test F.PATHS[:assets]   == joinpath(root, "_assets")
    @test F.PATHS[:css]      == joinpath(root, "_css")
    @test F.PATHS[:layout]   == joinpath(root, "_layout")
    @test F.PATHS[:libs]     == joinpath(root, "_libs")
    @test F.PATHS[:literate] == joinpath(root, "_literate")
    @test F.PATHS[:a_aux]    == joinpath(F.PATHS[:assets], "aux")
    @test F.PATHS[:a_infra]  == joinpath(F.PATHS[:assets], "infra")
    @test F.PATHS[:a_scripts]  == joinpath(F.PATHS[:assets], "scripts")
    @test F.PATHS[:a_literate] == joinpath(F.PATHS[:assets], "literate")

    # reset the structure to legacy for further tests
    F.FD_ENV[:STRUCTURE] = v"0.1"
end
