@testset "Comments" begin
	string = raw"""
	Hello hello
	<!--
	this is a comment
	blah
	-->
	Goodbye
	<!--
	blah
	-->
	"""
	string = JuDoc.remove_comments(string)
	@test string == "Hello hello\n\nGoodbye\n\n"
end

@testset "Asym Maths" begin
	# Just \[\]
	string = raw"""
		blahblah \[target\] blah
		\[target2\] blih
		"""
	(string, abm) = JuDoc.asym_math_blocks(string)
	@test string == raw"""
		blahblah ##ASYM_MATH_BLOCK##1 blah
		##ASYM_MATH_BLOCK##2 blih
		"""
	@test abm[1][2] == "target"
	@test abm[2][2] == "target2"

	# Just ALIGN
	string = raw"""
		blahblah \begin{align}target\end{align} blah
		\begin{align}target2\end{align} blih
		"""
	(string, abm) = JuDoc.asym_math_blocks(string)
	@test string == raw"""
		blahblah ##ASYM_MATH_BLOCK##1 blah
		##ASYM_MATH_BLOCK##2 blih
		"""
	@test abm[1][2] == "target"
	@test abm[2][2] == "target2"

	# Just EQNARRAY
	string = raw"""
		blahblah \begin{eqnarray}target\end{eqnarray} blah
		\begin{eqnarray}target2\end{eqnarray} blih
		"""
	(string, abm) = JuDoc.asym_math_blocks(string)
	@test string == raw"""
		blahblah ##ASYM_MATH_BLOCK##1 blah
		##ASYM_MATH_BLOCK##2 blih
		"""
	@test abm[1][2] == "target"
	@test abm[2][2] == "target2"

	# Mixed asymetric
	string = raw"""
		blahblah \begin{eqnarray}target\end{eqnarray} blah
		\[target2\] and \begin{align}
		target3
		\end{align}
		"""
	(string, abm) = JuDoc.asym_math_blocks(string)
	@test string == raw"""
		blahblah ##ASYM_MATH_BLOCK##3 blah
		##ASYM_MATH_BLOCK##1 and ##ASYM_MATH_BLOCK##2
		"""
	@test abm[1][2] == "target2"
	@test abm[2][2] == "\ntarget3\n"
	@test abm[3][2] == "target"
end


@testset "Sym Maths" begin
	# Just $ ... $
	string = raw"""
		blahblah $target$ blah
		$target2$ blih
		"""
	(string, sbm) = JuDoc.sym_math_blocks(string)
	@test string == raw"""
		blahblah ##SYM_MATH_BLOCK##1 blah
		##SYM_MATH_BLOCK##2 blih
		"""
	@test sbm[1][2] == "target"
	@test sbm[2][2] == "target2"

	# Just $$ ... $$
	string = raw"""
		blahblah $$target$$ blah
		$$target2$$ blih
		"""
	(string, sbm) = JuDoc.sym_math_blocks(string)
	@test string == raw"""
		blahblah ##SYM_MATH_BLOCK##1 blah
		##SYM_MATH_BLOCK##2 blih
		"""
	@test sbm[1][2] == "target"
	@test sbm[2][2] == "target2"

	# Mixed sym
	string = raw"""
		blahblah $target$ blah
		$$target2$$ blih
		"""
	(string, sbm) = JuDoc.sym_math_blocks(string)
	@test string == raw"""
		blahblah ##SYM_MATH_BLOCK##2 blah
		##SYM_MATH_BLOCK##1 blih
		"""
	@test sbm[1][2] == "target2"
	@test sbm[2][2] == "target"
end


@testset "Div Blocks" begin
	string = raw"""
		Yada yada yada
		@@warning target @@
		"""
	(string, db) = JuDoc.div_blocks(string)
	@test string == raw"""
		Yada yada yada
		##DIV_BLOCK##1
		"""
	@test db[1][1] == "warning"
	@test db[1][2] == " target "
end
