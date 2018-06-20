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
	(s, abm) = JuDoc.extract_asym_math_blocks(s);
	(s, sbm) = JuDoc.extract_sym_math_blocks(s);
	h = JuDoc.html(JuDoc.Markdown.parse(s));
	@test h == "<p>This is some <em>markdown</em> with ##SYM_MATH_BLOCK##2 some maths ##SYM_MATH_BLOCK##1 and maybe some more here ##ASYM_MATH_BLOCK##1 or whatever it is they prove in _Principia Mathematica_.</p>\n"
	h = JuDoc.process_math_blocks(h, abm, sbm)
	@test h == "<p>This is some <em>markdown</em> with \\(\\sin(x)=1\\) some maths \$\$ \\int_0^1 x\\mathrm{d}x = {1\\over 2} \$\$ and maybe some more here \$\$\n\\begin{array}{c}\n\t1+1 &=& 2\\\\\n\t2+2 &=& 4\n\\end{array}\n\$\$ or whatever it is they prove in _Principia Mathematica_.</p>\n"
end


@testset "Proc div b" begin
	t = raw"""
	blah
	@@d1 is blah @@d2
	and etc blah @@ and @@"""
	@test JuDoc.process_div_blocks(t) == "blah\n<div class=\"d1\"> is blah <div class=\"d2\">\nand etc blah </div>and </div>"
end


@testset "Proc esc" begin
	t = raw"""
	Hello
	~~~
	this should be escaped @@ ϵ π
	~~~
	Not **this**
	"""
	(h, eb) = JuDoc.extract_escaped_blocks(t)
	@test JuDoc.process_escaped_blocks(h, eb) == "Hello\nthis should be escaped @@ ϵ π\nNot **this**\n"
end
