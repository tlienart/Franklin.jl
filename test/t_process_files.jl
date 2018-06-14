@testset "MD > HTML" begin
	md_string = raw"""
	# Title
	This is some *markdown* with $\sin^2(x)+\cos^2(x)=1$ and
	also $$\sin^2(x)+\cos^2(x)\quad\!\!=\quad\!\!1 $$
	and maybe
	@@theorem
	dis a theorem with $$\exp(i\pi)+1=0$$ and
	@@
	maybe just some more text
	\begin{eqnarray}
		1 + 1 &=& 2
	\end{eqnarray}
	"""
	md_html, defs = JuDoc.convert_md(md_string)
	@test md_html =="<h1>Title</h1>\n<p>This is some <em>markdown</em> with \\(\\sin^2(x)+\\cos^2(x)=1\\) and also \$\$\\sin^2(x)+\\cos^2(x)\\quad\\!\\!=\\quad\\!\\!1 \$\$ and maybe <div class=\"theorem\">\ndis a theorem with \$\$\\exp(i\\pi)+1=0\$\$ and\n</div>\n maybe just some more text \$\$\n\\begin{array}{c}\n\t1 + 1 &=& 2\n\\end{array}\n\$\$</p>\n"
end

#=
	making a playground to test dirs and co
=#

temp_config = joinpath(JuDoc.JD_PATHS[:in], "config.md")
write(temp_config, "@def author = \"Stefan Zweig\"")
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


@testset "Prep outdir" begin
	JuDoc.prepare_output_dir()
	@test isdir(JuDoc.JD_PATHS[:out])
	@test isdir(JuDoc.JD_PATHS[:out_css])
	temp_out = joinpath(JuDoc.JD_PATHS[:out], "tmp.html")
	write(temp_out, "This is a test page.\n")
	# clear_out_dir is false => file should remain
	JuDoc.prepare_output_dir(false)
	@test isfile(temp_out)
	# clear_out_dir is true => file should go
	JuDoc.prepare_output_dir(true)
	@test !isfile(temp_out)
end

@testset "Scan dir" begin
	# it also tests add_if_new_file and last
	md_files = Dict{Pair{String, String}, Float64}()
	html_files = similar(md_files)
	other_files = similar(md_files)
	infra_files = similar(md_files)
	watched_files = [md_files, html_files, other_files, infra_files]
	JuDoc.scan_input_dir!(md_files, html_files, other_files, infra_files, true)
	@test haskey(md_files, JuDoc.JD_PATHS[:in_pages]=>"blah.md")
	@test md_files[JuDoc.JD_PATHS[:in_pages]=>"blah.md"] == JuDoc.last(temp_blah) == stat(temp_blah).mtime
	@test html_files[JuDoc.JD_PATHS[:in_pages]=>"temp.html"] == JuDoc.last(temp_html)
	@test other_files[JuDoc.JD_PATHS[:in_pages]=>"temp.rnd"] == JuDoc.last(temp_rnd)
end

@testset "Config+write" begin
	JuDoc.process_config()
	@test JuDoc.JD_GLOB_VARS["author"].first == "Stefan Zweig"
	rm(temp_config)
	@test_warn "I didn't find a config file. Ignoring." JuDoc.process_config()
	# testing write
	head = "head"
	pg_foot = "page_foot"
	foot = "foot [[if isnotes {{fill author}}]]"
	JuDoc.write_page(JuDoc.JD_PATHS[:in], "index.md", head, pg_foot, foot)
	out_file = JuDoc.out_path(JuDoc.JD_PATHS[:f]) * "index.html"
	@test isfile(out_file)
	@test readstring(out_file) == "head<div class=content>\n<p>blah blah</p>\npage_foot</div>foot  Stefan Zweig"
end

temp_config = joinpath(JuDoc.JD_PATHS[:in], "config.md")
write(temp_config, "@def author = \"Stefan Zweig\"")
rm(temp_index2)

@testset "Part convert" begin
	write(JuDoc.JD_PATHS[:in_html] * "head.html", raw"""
		<!doctype html>
		<html lang="en-UK">
			<head>
				<meta charset="UTF-8">
				<link rel="stylesheet" href="/css/main.css">
			</head>
		<body>""")
	write(JuDoc.JD_PATHS[:in_html] * "page_foot.html", raw"""
		<div class="page-foot">
				<div class="copyright">
						&copy; All rights reserved.
				</div>
		</div>""")
	write(JuDoc.JD_PATHS[:in_html] * "foot.html", raw"""
		    </body>
		</html>""")
	JuDoc.judoc()
	@test issubset(["css", "libs", "index.html"], readdir(JuDoc.JD_PATHS[:f]))
	@test issubset(["temp.html", "temp.rnd"], readdir(JuDoc.JD_PATHS[:out]))
	@test readstring(JuDoc.JD_PATHS[:f] * "index.html") == "<!doctype html>\n<html lang=\"en-UK\">\n\t<head>\n\t\t<meta charset=\"UTF-8\">\n\t\t<link rel=\"stylesheet\" href=\"/css/main.css\">\n\t</head>\n<body><div class=content>\n<p>blah blah</p>\n<div class=\"page-foot\">\n\t\t<div class=\"copyright\">\n\t\t\t\t&copy; All rights reserved.\n\t\t</div>\n</div></div>    </body>\n</html>"
	rm(temp_index)
	@test_warn "I didn't find an index.[md|html], there should be one. Ignoring." JuDoc.judoc()
end
