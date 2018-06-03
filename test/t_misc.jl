AAA = 5

@test_throws AssertionError JuDoc.set_paths!() # PATH_INPUT undef

td = tempdir() * "/"
PATH_INPUT = td

@testset "Extra utils" begin
	# ifisdef
	AAA = JuDoc.ifisdef(:AAA, 10)
	@test AAA == 5
	BBB = JuDoc.ifisdef(:BBB, 10)
	@test BBB == 10

	JuDoc.set_paths!()
	@test JuDoc.PATHS[:in] == td
	@test JuDoc.PATHS[:in_css] == td * "_css/"
	@test JuDoc.PATHS[:in_libs] == td * "_libs/"
	@test JuDoc.PATHS[:out] == "web_output/"
	@test JuDoc.PATHS[:out_css] == "web_output/_css/"
	@test JuDoc.PATHS[:out_libs] == "web_output/_libs/"
end
