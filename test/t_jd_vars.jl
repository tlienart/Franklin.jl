@testset "Set vars" begin
	d = Dict{String, Pair{Any, Tuple}}(
		"a" => 0.5 => (Real,),
		"b" => "hello" => (String, Void))
	JuDoc.set_vars!(d, ["a"=>"5", "b"=>"nothing"])
	@test d["a"].first == 5
	@test d["b"].first == nothing
	@test_warn "Doc var 'a' (type(s): (Real,)) can't be set to value 'blah' (type: String). Assignment ignored." JuDoc.set_vars!(d, ["a"=>"\"blah\""])
	@test_throws DomainError (@test_warn "I got an error trying to evaluate '__tmp__ = sqrt(-1)', fix the assignment." JuDoc.set_vars!(d, ["a"=> "sqrt(-1)"]))
	@test_warn "Doc var name 'blah' is unknown. Assignment ignored." JuDoc.set_vars!(d, ["blah"=>"1"])
end
