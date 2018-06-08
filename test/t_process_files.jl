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
	@test md_html == raw"""
	<h1>Title</h1>
	<p>This is some <em>markdown</em> with \(\sin^2(x)+\cos^2(x)=1\) and also $$\sin^2(x)+\cos^2(x)\quad\!\!=\quad\!\!1 $$ and maybe <div class="theorem">
	dis a theorem with ##SYM_MATH_BLOCK##2 and
	</div>
	 maybe just some more text $$
	\begin{array}{c}
		1 + 1 &=& 2
	\end{array}
	$$</p>
	"""
end

#=
	making a playground to test dirs and co
=#

PATH_INPUT = mktempdir() * "/"
PATH_OUTPUT = mktempdir() * "/"
mkdir(PATH_INPUT * "_css/")
mkdir(PATH_INPUT * "_libs/")
mkdir(PATH_INPUT * "_html_parts/")
JuDoc.set_paths!()

temp_index = joinpath(PATH_INPUT, "index.md")
write(temp_index, "blah blah")
temp_config = joinpath(PATH_INPUT, "config.md")
write(temp_config, "@def author = \"Stefan Zweig\"")
temp_html = joinpath(PATH_INPUT, "temp.html")
write(temp_html, "some html")
temp_rnd = joinpath(PATH_INPUT, "temp.rnd")
write(temp_rnd, "some random")


@testset "Prep outdir" begin
	# if PATH_OUTPUT doesn't exist, it is created
	rm(PATH_OUTPUT, recursive=true)
	JuDoc.prepare_output_dir()
	@test isdir(PATH_OUTPUT)
	@test isdir(JuDoc.JD_PATHS[:out_css])
	@test isdir(JuDoc.JD_PATHS[:out_libs])
	temp_out = joinpath(PATH_OUTPUT, "tmp.html")
	open(temp_out, "w") do f
		write(f, "This is a test page.\n")
	end
	# clear_out_dir is false => file should remain
	JuDoc.prepare_output_dir(false)
	@test isfile(temp_out)
	# clear_out_dir is true => file should go
	JuDoc.prepare_output_dir(true)
	@test !isfile(temp_out)
	# testing out_path while we're at it
	out_path = JuDoc.out_path(temp_index)
	@test ispath(out_path)
end

@testset "Scan dir" begin
	# it also tests add_if_new_file and last
	md_files = Dict{Pair{String, String}, Float64}()
	html_files = other_files = similar(md_files)
	watched_files = [md_files, html_files, other_files]
	JuDoc.scan_input_dir!(md_files, html_files, other_files, true)
	@test haskey(md_files, PATH_INPUT=>"index.md")
	@test md_files[PATH_INPUT=>"index.md"] == JuDoc.last(temp_index) == stat(temp_index).mtime
	@test html_files[PATH_INPUT=>"temp.html"] == JuDoc.last(temp_html)
	@test other_files[PATH_INPUT=>"temp.rnd"] == JuDoc.last(temp_rnd)
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
	JuDoc.write_page(PATH_INPUT, "index.md", head, pg_foot, foot)
	out_file = JuDoc.out_path(PATH_INPUT) * "index.html"
	@test isfile(out_file)
	@test readstring(out_file) == "head<div class=content>\n<p>blah blah</p>\npage_foot</div>foot  Stefan Zweig"
end
