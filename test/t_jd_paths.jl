AAA = 5

JuDoc.JD_PATHS[:in] = ""

@test_throws AssertionError JuDoc.set_paths!() # PATH_INPUT undef

td = mktempdir() * "/"
PATH_INPUT = td
#
@testset "Extra utils" begin
	# ifisdef
 	AAA = JuDoc.ifisdef(:AAA, 10)
 	@test AAA == 5
 	BBB = JuDoc.ifisdef(:BBB, 10)
 	@test BBB == 10

 	P = JuDoc.set_paths!()
 	@test JuDoc.JD_PATHS[:in] == td
 	@test JuDoc.JD_PATHS[:in_css] == td * "_css/"
 	@test JuDoc.JD_PATHS[:in_libs] == td * "_libs/"
 	@test JuDoc.JD_PATHS[:out] == "web_output/"
 	@test JuDoc.JD_PATHS[:out_css] == "web_output/_css/"
 	@test JuDoc.JD_PATHS[:out_libs] == "web_output/_libs/"
    @test P == JuDoc.JD_PATHS
end
