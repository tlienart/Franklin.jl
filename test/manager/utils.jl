fs1()

temp_config = joinpath(F.PATHS[:src], "config.md")
write(temp_config, raw"""
    @def author = "Stefan Zweig"
    @def automath = false
    @def autocode = false
    """)
temp_index = joinpath(F.PATHS[:src], "index.md")
write(temp_index, "blah blah")
temp_index2 = joinpath(F.PATHS[:src], "index.html")
write(temp_index2, "blah blih")
temp_blah = joinpath(F.PATHS[:src_pages], "blah.md")
write(temp_blah, "blah blah")
temp_html = joinpath(F.PATHS[:src_pages], "temp.html")
write(temp_html, "some html")
temp_rnd = joinpath(F.PATHS[:src_pages], "temp.rnd")
write(temp_rnd, "some random")
temp_css = joinpath(F.PATHS[:src_css], "temp.css")
write(temp_css, "some css")

F.process_config()

@testset "Prep outdir" begin
    F.prepare_output_dir()
    @test isdir(F.PATHS[:pub])
    @test isdir(F.PATHS[:css])
    temp_out = joinpath(F.PATHS[:pub], "tmp.html")
    write(temp_out, "This is a test page.\n")
    # clear is false => file should remain
    F.prepare_output_dir(false)
    @test isfile(temp_out)
    # clear is true => file should go
    F.prepare_output_dir(true)
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
    watched_files = [other_files, infra_files, md_files, html_files, literate_files]
    F.scan_input_dir!(other_files, infra_files, md_files, html_files, literate_files, true)
    @test haskey(md_files, F.PATHS[:src_pages]=>"blah.md")
    @test md_files[F.PATHS[:src_pages]=>"blah.md"] == mtime(temp_blah) == stat(temp_blah).mtime
    @test html_files[F.PATHS[:src_pages]=>"temp.html"] == mtime(temp_html)
    @test other_files[F.PATHS[:src_pages]=>"temp.rnd"] == mtime(temp_rnd)
end

@testset "Config+write" begin
    F.process_config()
    @test F.GLOBAL_VARS["author"].first == "Stefan Zweig"
    rm(temp_config)
    @test_logs (:warn, "I didn't find a config file. Ignoring.") F.process_config()
    # testing write
    head = "head"
    pg_foot = "\npage_foot"
    foot = "foot {{if hasmath}} {{fill author}}{{end}}"

    out_file = F.form_output_path(F.PATHS[:folder], "index.html", :html)
    F.write_page(F.PATHS[:src], "index.md", head, pg_foot, foot, out_file)

    @test isfile(out_file)
    @test read(out_file, String) == "head\n<div class=\"franklin-content\">\n<p>blah blah</p>\n\n\npage_foot\n</div>\nfoot  Stefan Zweig"
end

temp_config = joinpath(F.PATHS[:src], "config.md")
write(temp_config, "@def author = \"Stefan Zweig\"\n")
rm(temp_index2)

@testset "Part convert" begin # ✅ 16 aug 2018
    write(joinpath(F.PATHS[:src_html], "head.html"), raw"""
        <!doctype html>
        <html lang="en-UK">
            <head>
                <meta charset="UTF-8">
                <link rel="stylesheet" href="/css/main.css">
            </head>
        <body>""")
    write(joinpath(F.PATHS[:src_html], "page_foot.html"), raw"""
        <div class="page-foot">
                <div class="copyright">
                        &copy; All rights reserved.
                </div>
        </div>""")
    write(joinpath(F.PATHS[:src_html], "foot.html"), raw"""
            </body>
        </html>""")

    clear = true

    watched_files = F.fd_setup(; clear=clear)

    F.fd_fullpass(watched_files; clear=clear)

    @test issubset(["css", "libs", "index.html"], readdir(F.PATHS[:folder]))
    @test issubset(["temp.html", "temp.rnd"], readdir(F.PATHS[:pub]))
    @test all(split(read(joinpath(F.PATHS[:folder], "index.html"), String)) .== split("<!doctype html>\n<html lang=\"en-UK\">\n\t<head>\n\t\t<meta charset=\"UTF-8\">\n\t\t<link rel=\"stylesheet\" href=\"/css/main.css\">\n\t</head>\n<body>\n<div class=\"franklin-content\">\n<p>blah blah</p>\n\n<div class=\"page-foot\">\n\t\t<div class=\"copyright\">\n\t\t\t\t&copy; All rights reserved.\n\t\t</div>\n</div>\n</div>\n    </body>\n</html>"))
end

@testset "Err procfile" begin
    write(temp_index, "blah blah { blih etc")
    println("🐝 Testing error message...:")
    @test_throws F.OCBlockError F.process_file_err(:md, F.PATHS[:src] => "index.md"; clear=false)
end
