#=
	making a playground to test dirs and co
=#

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


@testset "Prep outdir" begin # ✅ aug 15, 2018
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


@testset "Scan dir" begin # ✅ aug 15, 2018
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
	pg_foot = "\npage_foot"
	foot = "foot {{if isnotes}} {{fill author}}{{end}}"

	JuDoc.write_page(JuDoc.JD_PATHS[:in], "index.md", head, pg_foot, foot)
	out_file = JuDoc.out_path(JuDoc.JD_PATHS[:f]) * "index.html"
	@test isfile(out_file)
	@test readstring(out_file) == "head<div class=content>\nblah blah\npage_foot</div>foot  Stefan Zweig"
end
