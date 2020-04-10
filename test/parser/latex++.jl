# Let's test latex commands to death... especially in light of #444

@testset "lx++1" begin
    # 444
    s = "\\newcommand{\\note}[1]{#1} \\note{A `B` C} D" |> fd2html_td
    @test isapproxstr(s, """
        A <code>B</code> C D
        """)
    s = raw"""
        \newcommand{\note}[1]{@@note #1 @@}
        \note{A}
        \note{A `B` C}
        \note{A @@cc B @@ D}
        \note{A @@cc B `D` E @@ F}
        """ |> fd2html_td
    @test isapproxstr(s, """
        <div class="note">A</div>
        <div class="note">A <code>B</code> C</div>
        <div class="note">A <div class="cc">B</div> D</div>
        <div class="note">A <div class="cc">B <code>D</code> E</div> F</div>
        """)
end
