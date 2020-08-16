fs2()

temp_config = joinpath(F.PATHS[:folder], "config.md")
write(temp_config, raw"""
    @def author = "Stefan Zweig"
    @def automath = false
    @def autocode = false
    """)
temp_index = joinpath(F.PATHS[:folder], "index.md")
write(temp_index, "blah blah")
temp_index2 = joinpath(F.PATHS[:folder], "index.html")
write(temp_index2, "blah blih")
temp_blah = joinpath(F.PATHS[:folder], "blah.md")
write(temp_blah, "blah blah")
temp_html = joinpath(F.PATHS[:folder], "temp.html")
write(temp_html, "some html")
temp_rnd = joinpath(F.PATHS[:folder], "temp.rnd")
write(temp_rnd, "some random")
temp_css = joinpath(F.PATHS[:css], "temp.css")
write(temp_css, "some css")
temp_js = joinpath(F.PATHS[:libs], "foo.js")
write(temp_js, "some js")

F.process_config()

@testset "Prep outdir" begin
    F.prepare_output_dir()
    @test isdir(F.PATHS[:site])
    temp_out = joinpath(F.PATHS[:site], "tmp.html")
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
    md_files       = Dict{Pair{String, String}, Float64}()
    html_files     = empty(md_files)
    other_files    = empty(md_files)
    infra_files    = empty(md_files)
    literate_files = empty(md_files)
    watched_files  = [other_files, infra_files, md_files, html_files, literate_files]
    F.scan_input_dir!(other_files, infra_files, md_files, html_files, literate_files, true)
    @test haskey(md_files, F.PATHS[:folder]=>"blah.md")
    @test md_files[F.PATHS[:folder]=>"blah.md"] == mtime(temp_blah) == stat(temp_blah).mtime
    @test html_files[F.PATHS[:folder]=>"temp.html"] == mtime(temp_html)
    @test other_files[F.PATHS[:folder]=>"temp.rnd"] == mtime(temp_rnd)
end

@testset "Config+write" begin
    F.process_config()
    @test F.GLOBAL_VARS["author"].first == "Stefan Zweig"
    rm(temp_config)
    @test_logs (:warn, "I didn't find a config file. Ignoring.") F.process_config()
    # testing write
    head = "head"
    pg_foot = "\npage_foot"
    foot = "foot {{fill author}}"

    out_file = F.form_output_path(F.PATHS[:site], "index.html", :html)
    F.convert_and_write(F.PATHS[:folder], "index.md", head, pg_foot, foot, out_file)

    @test isfile(out_file)
    @test isapproxstr(read(out_file, String), """
        head\n<div class=\"franklin-content\">\n<p>blah blah</p>\n\n\npage_foot\n</div>\nfoot  Stefan Zweig""")
end

temp_config = joinpath(F.PATHS[:folder], "config.md")
write(temp_config, "@def author = \"Stefan Zweig\"\n")
rm(temp_index2)

@testset "Part convert" begin
    write(joinpath(F.PATHS[:layout], "head.html"), raw"""
        <!doctype html>
        <html lang="en-UK">
            <head>
                <meta charset="UTF-8">
                <link rel="stylesheet" href="/css/main.css">
            </head>
        <body>""")
    write(joinpath(F.PATHS[:layout], "page_foot.html"), raw"""
        <div class="page-foot">
                <div class="copyright">
                        &copy; All rights reserved.
                </div>
        </div>""")
    write(joinpath(F.PATHS[:layout], "foot.html"), raw"""
            </body>
        </html>""")

    clear = true

    watched_files = F.fd_setup(; clear=clear)

    F.fd_fullpass(watched_files; clear=clear)

    @test issubset(["css", "libs", "index.html"], readdir(F.PATHS[:site]))
    @test issubset(["temp", "temp.rnd"], readdir(F.PATHS[:site]))
    @test issubset(["index.html"], readdir(joinpath(F.PATHS[:site], "temp")))
    @test issubset(["index.html"], readdir(joinpath(F.PATHS[:site], "blah")))
end

@testset "Err procfile" begin
    write(temp_index, "blah blah { blih etc")
    println("🐝 Testing error message...:")
    @test_throws F.OCBlockError F.process_file_err(:md, F.PATHS[:folder] => "index.md"; clear=false)
end
