@testset "Div-pattern util" begin
	t = JuDoc.dpat("blah", "content is here")
	@test t == "<div class=\"blah\">content is here</div>\n"
end


@testset "Process-math blocks" begin
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
end
