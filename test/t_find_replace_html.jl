@testset "Proc math b" begin
	s = raw"""
	This is some *markdown* with $\sin(x)=1$ some maths
	$$ \int_0^1 x\mathrm{d}x = {1\over 2} $$
	and maybe some more here
	\begin{eqnarray}
		1+1 &=& 2\\
		2+2 &=& 4
	\end{eqnarray}
	or whatever it is they prove in _Principia Mathematica_.
	"""
	(s, abm) = JuDoc.asym_math_blocks(s);
	(s, sbm) = JuDoc.sym_math_blocks(s);
	h = JuDoc.html(JuDoc.Markdown.parse(s));
	@test h == "<p>This is some <em>markdown</em> with ##SYM_MATH_BLOCK##2 some maths ##SYM_MATH_BLOCK##1 and maybe some more here ##ASYM_MATH_BLOCK##1 or whatever it is they prove in _Principia Mathematica_.</p>\n"
	h = JuDoc.process_math_blocks(h, abm, sbm)
	@test h == "<p>This is some <em>markdown</em> with \\(\\sin(x)=1\\) some maths \$\$ \\int_0^1 x\\mathrm{d}x = {1\\over 2} \$\$ and maybe some more here \$\$\n\\begin{array}{c}\n\t1+1 &=& 2\\\\\n\t2+2 &=& 4\n\\end{array}\n\$\$ or whatever it is they prove in _Principia Mathematica_.</p>\n"
end


@testset "Proc div b" begin
	t = JuDoc.dpat("blah", "content is here")
	@test t == "<div class=\"blah\">content is here</div>\n"
	s = raw"""
	This is some *markdown* followed by a div:
	@@some_div
	the content here
	@@ and then more markdown
	blah.
	"""
	s, b = JuDoc.div_blocks(s)
	@test s == "This is some *markdown* followed by a div:\n##DIV_BLOCK##1 and then more markdown\nblah.\n"
	@test b == ["some_div"=>"\nthe content here\n"]
	h = JuDoc.html(JuDoc.Markdown.parse(s));
	h = JuDoc.process_div_blocks(h, b)
	@test h == "<p>This is some <em>markdown</em> followed by a div: <div class=\"some_div\">\nthe content here\n</div>\n and then more markdown blah.</p>\n"
end


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

@testset "Proc [[if]] b" begin
	vars = Dict(
		"flag" => true=>(Bool,),
		"fflag" => false=>(Bool,),
		"filler" => 245=>(Int,))
	h = """
	blah blah [[ if flag blah blah {{fill filler}} ]]
	and then [[ if fflag
	nothing should
	]]
	be here
	"""
	h′ = JuDoc.process_if_sqbr_blocks(h, vars)
	@test h′ == "blah blah  blah blah {{fill filler}} \nand then \nbe here\n"
	h2 = """
	blah blah [[if noflag blih end]] bloh
	"""
	@test_warn "I found a [[if noflag ... ]] block but I don't know the variable 'noflag'. Default assumption = it's false." JuDoc.process_if_sqbr_blocks(h2, vars)
	h′ = JuDoc.process_html_blocks(h, vars)
	h′ == "blah blah  blah blah 245 \nand then \nbe here\n"
end
