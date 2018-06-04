@testset "Set vars" begin
	d = Dict(
		"a" => [0.5, (Real,)],
		"b" => ["hello", (String, Void)])
	JuDoc.set_vars!(d, [("a", "=5"), ("b", "=nothing")])
	@test d["a"][1] == 5.0
	@test d["b"][1] == nothing
	@test_warn "Doc var 'a' (types: (Real,)) can't be set to value 'blah' (type: String). Assignment ignored." JuDoc.set_vars!(d, [("a", "=\"blah\"")])
	@test_throws DomainError (@test_warn "I got an error trying to evaluate '__tmp__ = sqrt(-1)', fix the assignment." JuDoc.set_vars!(d, [("a", "=sqrt(-1)")]))
	@test_warn "Doc var name 'blah' is unknown. Assignment ignored." JuDoc.set_vars!(d, [("blah", "=1")])
end

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
	md_html = JuDoc.convert_md!(Dict(), md_string)
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
