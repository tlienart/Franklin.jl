@testset "fill" begin
    s = """
        @def x = 5
        {{fill x}}
        """ |> fd2html_td
    @test isapproxstr(s, "5")
    @test_throws F.HTMLFunctionError ("{{fill x y z}}" |> fd2html)
end

@testset "href" begin
    s = "{{href EQR foo}}" |> fd2html_td
    @test isapproxstr(s, "<b>??</b>")
end

@testset "redirect" begin
    # only one arg
    @test_throws F.HTMLFunctionError ("{{redirect foo bar}}" |> fd2html)
    # must end with html
    @test_throws F.HTMLFunctionError ("{{redirect foo}}" |> fd2html)
end
