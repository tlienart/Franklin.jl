@testset "Bold x*" begin # issue 223
    h = raw"**x\***" * J.EOS |> seval
    @test h == "<p><strong>x&#42;</strong></p>\n"

    h = raw"_x\__" * J.EOS |> seval
    @test h == "<p><em>x&#95;</em></p>\n"
end
