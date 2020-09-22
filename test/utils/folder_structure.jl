@testset "set_paths!" begin
    F.def_GLOBAL_VARS!()
    root = F.FOLDER_PATH[] = mktempdir()
    empty!(F.PATHS); F.set_paths!()
    @test Set(keys(F.PATHS)) == Set([:folder, :assets, :css, :layout, :libs, :literate, :site, :tag])
    @test F.PATHS[:folder]   == root
    @test F.PATHS[:site]     == joinpath(root, "__site")
    @test F.PATHS[:assets]   == joinpath(root, "_assets")
    @test F.PATHS[:css]      == joinpath(root, "_css")
    @test F.PATHS[:layout]   == joinpath(root, "_layout")
    @test F.PATHS[:libs]     == joinpath(root, "_libs")
    @test F.PATHS[:literate] == joinpath(root, "_literate")
    @test F.PATHS[:tag]      == joinpath(root, "__site", "tag")
end

@testset "outp_path" begin
    empty!(F.PATHS); F.set_paths!()

    # MD_PAGES
    base = F.PATHS[:folder]
    file = "index.md"
    out = F.form_output_path(base, file, :md)
    @test out == joinpath(F.PATHS[:site], "index.html")

    file = "index.html"
    out = F.form_output_path(base, file, :html)
    @test out == joinpath(F.PATHS[:site], "index.html")

    file = "page.md"
    out = F.form_output_path(base, file, :md)
    @test out == joinpath(F.PATHS[:site], "page", "index.html")

    file = "page.html"
    out = F.form_output_path(base, file, :html)
    @test out == joinpath(F.PATHS[:site], "page", "index.html")

    file = "index.md"
    base = joinpath(F.PATHS[:folder], "menu")
    out = F.form_output_path(base, file, :md)
    @test out == joinpath(F.PATHS[:site], "menu", "index.html")

    file = "index.html"
    out = F.form_output_path(base, file, :html)
    @test out == joinpath(F.PATHS[:site], "menu", "index.html")

    file = "page.md"
    out = F.form_output_path(base, file, :md)
    @test out == joinpath(F.PATHS[:site], "menu", "page", "index.html")

    # OTHER STUFF
    file = "foo.css"
    base = F.PATHS[:css]
    out = F.form_output_path(base, file, :infra)
    @test out == joinpath(F.PATHS[:site], "css", "foo.css")
    file = "lib.js"
    base = F.PATHS[:libs]
    out = F.form_output_path(base, file, :infra)
    @test out == joinpath(F.PATHS[:site], "libs", "lib.js")
end
