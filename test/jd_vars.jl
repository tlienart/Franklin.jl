@testset "Set vars" begin
    d = Dict{String, Pair{Any, Tuple}}(
    	"a" => 0.5 => (Real,),
    	"b" => "hello" => (String, Nothing))
    JuDoc.set_vars!(d, ["a"=>"5", "b"=>"nothing"])
    @test d["a"].first == 5
    @test d["b"].first == nothing
    @test (@test_logs (:warn, "Doc var 'a' (type(s): (Real,)) can't be set to value 'blah' (type: String). Assignment ignored.") JuDoc.set_vars!(d, ["a"=>"\"blah\""])) == nothing
    @test (@test_logs (:error, "I got an error (of type 'DomainError') trying to evaluate '__tmp__ = sqrt(-1)', fix the assignment.") JuDoc.set_vars!(d, ["a"=> "sqrt(-1)"])) == nothing
    @test (@test_logs (:warn, "Doc var name 'blah' is unknown. Assignment ignored.") JuDoc.set_vars!(d, ["blah"=>"1"])) == nothing
end
