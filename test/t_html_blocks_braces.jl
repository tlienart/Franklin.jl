@testset "Proc {{.}} b" begin
	# split param util
	params = "blah blih thing"
	@test_warn "I found a 'FNAME' and expected 2 argument(s) but got 3 instead. Ignoring." JuDoc.split_params(params, "FNAME", 2)
	(f, sp) = JuDoc.split_params(params, "FNAME", 3)
	@test f == true
	@test sp == ["blah", "blih", "thing"]

	# replacements :: braces_fill
	params1 = "blah"
	var1 = Dict("blah" => 25=>(Int,))
	r = JuDoc.braces_fill(params1, var1)
	@test r == "25"
	params1 = "blih"
	@test_warn "I found a '{{fill blih}}' but I do not know the variable 'blih'. Ignoring." JuDoc.braces_fill(params1, var1)
	params2 = "blih blah"
	@test_warn "I found a 'fill' and expected 1 argument(s) but got 2 instead. Ignoring." JuDoc.braces_fill(params2, var1)

	# replacements :: braces_insert
	temp_path = joinpath(JuDoc.JD_PATHS[:in_html], "tmp")
	write(temp_path * ".html", "This is a test page.\n")
	params2 = " tmp "
	vars = Dict("flag" => true=>(Bool,))
	r = JuDoc.braces_insert(params2, vars)
	@test r == "This is a test page.\n"
	params2 = "non-existing"
	@test_warn "I tried to insert '$(JuDoc.JD_PATHS[:in_html])non-existing.html' but I couldn't find the file. Ignoring." JuDoc.braces_insert(params2, vars)

	# replacements :: general braces blocks
	h = """
	blah blah {{ fill blah }} and
	then some more stuff maybe {{ insert tmp }} etc
	blah
	"""
	vars = Dict("blah" => 0.123=>(Float64,), "flag" => true=>(Bool,))
	h = JuDoc.process_braces_blocks(h, vars)
	@test h == "blah blah 0.123 and\nthen some more stuff maybe This is a test page.\n etc\nblah\n"
	h = """
	{{ unknown f f2 }}
	"""
	@test_warn "I found a {{unknown...}} block but did not recognise the function name 'unknown'. Ignoring." JuDoc.process_braces_blocks(h, vars)
end
