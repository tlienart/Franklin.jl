@testset "Comments" begin
	s = raw"""
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
	s = JuDoc.remove_comments(s)
	@test s == "Hello hello\n\nGoodbye\n\n"
end


@testset "Page defs" begin
	s = raw"""
	@def hasmath = false
	@def hascode = true

	Blah etc
	"""
	(s, defs) = JuDoc.extract_page_vars_defs(s)
	@test s == "\n\n\nBlah etc\n"
	@test defs == ["hasmath"=>" = false", "hascode"=>" = true"]
end
