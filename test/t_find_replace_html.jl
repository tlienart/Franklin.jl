@testset "Process math blocks" begin
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


@testset "Process div blocks" begin
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
	@test b == [("some_div", "\nthe content here\n")]
	h = JuDoc.html(JuDoc.Markdown.parse(s));
	h = JuDoc.process_div_blocks(h, b)
	@test h == "<p>This is some <em>markdown</em> followed by a div: <div class=\"some_div\">\nthe content here\n</div>\n and then more markdown blah.</p>\n"
end


@testset "Process braces blocks" begin
	# split param util
	params = "blah blih bloh"
	@test_warn "I found a FNAME and expected 2 arguments but got 3 instead. Ignoring." JuDoc.split_params(params, "FNAME", 2)
	(f, sp) = JuDoc.split_params(params, "FNAME", 3)
	@test f == true
	@test sp == ["blah", "blih", "bloh"]
end
