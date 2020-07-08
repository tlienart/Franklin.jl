# Let's test latex commands to death... especially in light of #444

@testset "lx++1" begin
    # 444
    s = "\\newcommand{\\note}[1]{#1} \\note{A `B` C} D" |> fd2html_td
    @test isapproxstr(s, """
        <p>A <code>B</code> C D</p>
        """)
end
