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
