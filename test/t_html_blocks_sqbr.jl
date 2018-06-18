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
