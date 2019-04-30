temp_config = joinpath(JuDoc.JD_PATHS[:in], "config.md")
write(temp_config, "@def author = \"Stefan Zweig\"\n")
temp_index = joinpath(JuDoc.JD_PATHS[:in], "index.md")
write(temp_index, "blah blah")
temp_index2 = joinpath(JuDoc.JD_PATHS[:in], "index.html")
write(temp_index2, "blah blih")
temp_blah = joinpath(JuDoc.JD_PATHS[:in_pages], "blah.md")
write(temp_blah, "blah blah")
temp_html = joinpath(JuDoc.JD_PATHS[:in_pages], "temp.html")
write(temp_html, "some html")
temp_rnd = joinpath(JuDoc.JD_PATHS[:in_pages], "temp.rnd")
write(temp_rnd, "some random")
temp_css = joinpath(JuDoc.JD_PATHS[:in_css], "temp.css")
write(temp_css, "some css")

JuDoc.process_config()

@testset "Prep outdir" begin # ✅ aug 15, 2018
    JuDoc.prepare_output_dir()
    @test isdir(JuDoc.JD_PATHS[:out])
    @test isdir(JuDoc.JD_PATHS[:out_css])
    temp_out = joinpath(JuDoc.JD_PATHS[:out], "tmp.html")
    write(temp_out, "This is a test page.\n")
    # clear is false => file should remain
    JuDoc.prepare_output_dir(false)
    @test isfile(temp_out)
    # clear is true => file should go
    JuDoc.prepare_output_dir(true)
    @test !isfile(temp_out)
end

@testset "Scan dir" begin # ✅ aug 16, 2018
    println("🐝 Testing file tracking...:")
    # it also tests add_if_new_file and last
    md_files = Dict{Pair{String, String}, Float64}()
    html_files = empty(md_files)
    other_files = empty(md_files)
    infra_files = empty(md_files)
    watched_files = [md_files, html_files, other_files, infra_files]
    JuDoc.scan_input_dir!(md_files, html_files, other_files, infra_files, true)
    @test haskey(md_files, JuDoc.JD_PATHS[:in_pages]=>"blah.md")
    @test md_files[JuDoc.JD_PATHS[:in_pages]=>"blah.md"] == mtime(temp_blah) == stat(temp_blah).mtime
    @test html_files[JuDoc.JD_PATHS[:in_pages]=>"temp.html"] == mtime(temp_html)
    @test other_files[JuDoc.JD_PATHS[:in_pages]=>"temp.rnd"] == mtime(temp_rnd)
end

@testset "Config+write" begin # ✅ 4 Sept, 2018
    JuDoc.process_config()
    @test JuDoc.JD_GLOB_VARS["author"].first == "Stefan Zweig"
    rm(temp_config)
    @test_logs (:warn, "I didn't find a config file. Ignoring.")  JuDoc.process_config()
    # testing write
    head = "head"
    pg_foot = "\npage_foot"
    foot = "foot {{if hasmath}} {{fill author}}{{end}}"

    JuDoc.write_page(JuDoc.JD_PATHS[:in], "index.md", head, pg_foot, foot)
    out_file = joinpath(JuDoc.out_path(JuDoc.JD_PATHS[:f]), "index.html")

    @test isfile(out_file)
    @test read(out_file, String) == "head\n<div class=\"jd-content\">\n<p>blah blah</p>\n\n\npage_foot\n</div>\nfoot  Stefan Zweig"
end


temp_config = joinpath(JuDoc.JD_PATHS[:in], "config.md")
write(temp_config, "@def author = \"Stefan Zweig\"\n")
rm(temp_index2)


@testset "Part convert" begin # ✅ 16 aug 2018
    write(joinpath(JuDoc.JD_PATHS[:in_html], "head.html"), raw"""
        <!doctype html>
        <html lang="en-UK">
            <head>
                <meta charset="UTF-8">
                <link rel="stylesheet" href="/css/main.css">
            </head>
        <body>""")
    write(joinpath(JuDoc.JD_PATHS[:in_html], "page_foot.html"), raw"""
        <div class="page-foot">
                <div class="copyright">
                        &copy; All rights reserved.
                </div>
        </div>""")
    write(joinpath(JuDoc.JD_PATHS[:in_html], "foot.html"), raw"""
            </body>
        </html>""")

    clear = true

    watched_files = J.jd_setup(; clear=clear)

    J.jd_fullpass(watched_files; clear=clear)

    @test issubset(["css", "libs", "index.html"], readdir(JuDoc.JD_PATHS[:f]))
    @test issubset(["temp.html", "temp.rnd"], readdir(JuDoc.JD_PATHS[:out]))
    @test all(split(read(joinpath(JuDoc.JD_PATHS[:f], "index.html"), String)) .== split("<!doctype html>\n<html lang=\"en-UK\">\n\t<head>\n\t\t<meta charset=\"UTF-8\">\n\t\t<link rel=\"stylesheet\" href=\"/css/main.css\">\n\t</head>\n<body>\n<div class=\"jd-content\">\n<p>blah blah</p>\n\n<div class=\"page-foot\">\n\t\t<div class=\"copyright\">\n\t\t\t\t&copy; All rights reserved.\n\t\t</div>\n</div>\n</div>\n    </body>\n</html>"))
end


@testset "Err procfile" begin
    write(temp_index, "blah blah { blih etc")
    println("🐝 Testing error message...:")
    @test_throws ErrorException JuDoc.process_file_err(:md, JuDoc.JD_PATHS[:in] => "index.md"; clear=false)
end
