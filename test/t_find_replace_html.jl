@testset "Div-pattern" begin
	t = JuDoc.dpat("blah", "content is here")
	@test t == "<div class=\"blah\">content is here</div>\n"
end
