AAA = 5

@test_throws AssertionError JuDoc.set_paths!() # PATH_INPUT undef

PATH_INPUT = "test/"

@testset "Extra utils" begin
	# ifisdef
	AAA = JuDoc.ifisdef(:AAA, 10)
	@test AAA == 5
	BBB = JuDoc.ifisdef(:BBB, 10)
	@test BBB == 10

	JuDoc.set_paths!()
	@test JuDoc.PATHS[:in] == "test/"
	@test JuDoc.PATHS[:in_css] == "test/_css/"
	@test JuDoc.PATHS[:in_libs] == "test/_libs/"
	@test JuDoc.PATHS[:out] == "web_output/"
	@test JuDoc.PATHS[:out_css] == "web_output/_css/"
	@test JuDoc.PATHS[:out_libs] == "web_output/_libs/"
end
