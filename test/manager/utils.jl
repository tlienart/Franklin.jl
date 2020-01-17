temp_config = joinpath(Franklin.PATHS[:src], "config.md")
write(temp_config, "@def author = \"Stefan Zweig\"\n")
temp_index = joinpath(Franklin.PATHS[:src], "index.md")
write(temp_index, "blah blah")
temp_index2 = joinpath(Franklin.PATHS[:src], "index.html")
write(temp_index2, "blah blih")
temp_blah = joinpath(Franklin.PATHS[:src_pages], "blah.md")
write(temp_blah, "blah blah")
temp_html = joinpath(Franklin.PATHS[:src_pages], "temp.html")
write(temp_html, "some html")
temp_rnd = joinpath(Franklin.PATHS[:src_pages], "temp.rnd")
write(temp_rnd, "some random")
temp_css = joinpath(Franklin.PATHS[:src_css], "temp.css")
write(temp_css, "some css")

Franklin.process_config()

@testset "Prep outdir" begin
    Franklin.prepare_output_dir()
    @test isdir(Franklin.PATHS[:pub])
    @test isdir(Franklin.PATHS[:css])
    temp_out = joinpath(Franklin.PATHS[:pub], "tmp.html")
    write(temp_out, "This is a test page.\n")
    # clear is false => file should remain
    Franklin.prepare_output_dir(false)
    @test isfile(temp_out)
    # clear is true => file should go
    Franklin.prepare_output_dir(true)
    @test !isfile(temp_out)
end

@testset "Scan dir" begin
    println("🐝 Testing file tracking...:")
    # it also tests add_if_new_file and last
    md_files = Dict{Pair{String, String}, Float64}()
    html_files = empty(md_files)
    other_files = empty(md_files)
    infra_files = empty(md_files)
    literate_files = empty(md_files)
    watched_files = [md_files, html_files, other_files, infra_files, literate_files]
    Franklin.scan_input_dir!(md_files, html_files, other_files, infra_files, literate_files, true)
    @test haskey(md_files, Franklin.PATHS[:src_pages]=>"blah.md")
    @test md_files[Franklin.PATHS[:src_pages]=>"blah.md"] == mtime(temp_blah) == stat(temp_blah).mtime
    @test html_files[Franklin.PATHS[:src_pages]=>"temp.html"] == mtime(temp_html)
    @test other_files[Franklin.PATHS[:src_pages]=>"temp.rnd"] == mtime(temp_rnd)
end

@testset "Config+write" begin
    Franklin.process_config()
    @test Franklin.GLOBAL_PAGE_VARS["author"].first == "Stefan Zweig"
    rm(temp_config)
    @test_logs (:warn, "I didn't find a config file. Ignoring.")  Franklin.process_config()
    # testing write
    head = "head"
    pg_foot = "\npage_foot"
    foot = "foot {{if hasmath}} {{fill author}}{{end}}"

    Franklin.write_page(Franklin.PATHS[:src], "index.md", head, pg_foot, foot)
    out_file = joinpath(Franklin.out_path(Franklin.PATHS[:folder]), "index.html")

    @test isfile(out_file)
    @test read(out_file, String) == "head\n<div class=\"jd-content\">\n<p>blah blah</p>\n\n\npage_foot\n</div>\nfoot  Stefan Zweig"
end


temp_config = joinpath(Franklin.PATHS[:src], "config.md")
write(temp_config, "@def author = \"Stefan Zweig\"\n")
rm(temp_index2)

@testset "Part convert" begin # ✅ 16 aug 2018
    write(joinpath(Franklin.PATHS[:src_html], "head.html"), raw"""
        <!doctype html>
        <html lang="en-UK">
            <head>
                <meta charset="UTF-8">
                <link rel="stylesheet" href="/css/main.css">
            </head>
        <body>""")
    write(joinpath(Franklin.PATHS[:src_html], "page_foot.html"), raw"""
        <div class="page-foot">
                <div class="copyright">
                        &copy; All rights reserved.
                </div>
        </div>""")
    write(joinpath(Franklin.PATHS[:src_html], "foot.html"), raw"""
            </body>
        </html>""")

    clear = true

    watched_files = J.jd_setup(; clear=clear)

    J.jd_fullpass(watched_files; clear=clear)

    @test issubset(["css", "libs", "index.html"], readdir(Franklin.PATHS[:folder]))
    @test issubset(["temp.html", "temp.rnd"], readdir(Franklin.PATHS[:pub]))
    @test all(split(read(joinpath(Franklin.PATHS[:folder], "index.html"), String)) .== split("<!doctype html>\n<html lang=\"en-UK\">\n\t<head>\n\t\t<meta charset=\"UTF-8\">\n\t\t<link rel=\"stylesheet\" href=\"/css/main.css\">\n\t</head>\n<body>\n<div class=\"jd-content\">\n<p>blah blah</p>\n\n<div class=\"page-foot\">\n\t\t<div class=\"copyright\">\n\t\t\t\t&copy; All rights reserved.\n\t\t</div>\n</div>\n</div>\n    </body>\n</html>"))
end


@testset "Err procfile" begin
    write(temp_index, "blah blah { blih etc")
    println("🐝 Testing error message...:")
    @test_throws J.OCBlockError Franklin.process_file_err(:md, Franklin.PATHS[:src] => "index.md"; clear=false)
end
