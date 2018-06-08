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

PATH_INPUT = mktempdir() * "/"
PATH_OUTPUT = mktempdir() * "/"
mkdir(PATH_INPUT * "_css/")
mkdir(PATH_INPUT * "_libs/")
mkdir(PATH_INPUT * "_html_parts/")
JuDoc.set_paths!()

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
end

#using JuDoc, Base.Test
