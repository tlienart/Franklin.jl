@testset "set_paths!" begin
    F.def_GLOBAL_VARS!()
    root = F.FOLDER_PATH[] = mktempdir()
    empty!(F.PATHS); F.FD_ENV[:STRUCTURE] = v"0.1"; F.set_paths!()
    @test Set(keys(F.PATHS)) == Set([:folder, :src, :src_pages, :src_css, :src_html, :pub, :css, :libs, :assets, :literate, :tag])
    @test F.PATHS[:folder] == root
    @test F.PATHS[:src_pages] == joinpath(F.PATHS[:src], "pages")

    # ================================================
    empty!(F.PATHS); F.FD_ENV[:STRUCTURE] = v"0.2"; F.set_paths!()
    @test Set(keys(F.PATHS)) == Set([:folder, :assets, :css, :layout, :libs, :literate, :site, :tag])
    @test F.PATHS[:folder]   == root
    @test F.PATHS[:site]     == joinpath(root, "__site")
    @test F.PATHS[:assets]   == joinpath(root, "_assets")
    @test F.PATHS[:css]      == joinpath(root, "_css")
    @test F.PATHS[:layout]   == joinpath(root, "_layout")
    @test F.PATHS[:libs]     == joinpath(root, "_libs")
    @test F.PATHS[:literate] == joinpath(root, "_literate")
    @test F.PATHS[:tag]      == joinpath(root, "__site", "tag")

    # ================================================
    # reset the structure to legacy for further tests
    empty!(F.PATHS); F.FD_ENV[:STRUCTURE] = v"0.1"; F.set_paths!()
end

@testset "outp_path" begin
    empty!(F.PATHS); F.FD_ENV[:STRUCTURE] = v"0.1"; F.set_paths!()
    # MD_PAGES
    out = F.form_output_path(F.PATHS[:src], "index.md", :md)
    @test out == joinpath(F.PATHS[:folder], "index.html")

    out = F.form_output_path(F.PATHS[:src_pages], "foo.md", :md)
    @test out == joinpath(F.PATHS[:folder], "pub", "foo.html")

    # CSS
    out = F.form_output_path(F.PATHS[:src_css], "foo.css", :infra)
    @test out == joinpath(F.PATHS[:css], "foo.css")

    # (note: assets, libs are not tracked and not considered in v1)

    # ================================================

    empty!(F.PATHS); F.FD_ENV[:STRUCTURE] = v"0.2"; F.set_paths!()

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

    # ================================================

    empty!(F.PATHS); F.FD_ENV[:STRUCTURE] = v"0.1"; F.set_paths!()
end
