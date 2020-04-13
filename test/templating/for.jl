@testset "for-basic" begin
    s = """
        @def v1 = [1, 2, 3]
        ~~~
        {{for v in v1}}
            v: {{fill v}}
        {{end}}
        ~~~
        """ |> fd2html_td
    @test isapproxstr(s, """
        v: 1
        v: 2
        v: 3
        """)

    s = """
        @def v1 = [[1,2], [3,4]]
        ~~~
        {{for (a,b) in v1}}
            a: {{fill a}} b: {{fill b}}
        {{end}}
        ~~~
        """ |> fd2html_td
    @test isapproxstr(s, """
        a: 1 b: 2
        a: 3 b: 4
        """)

    s = """
        @def v_1 = ("a"=>1, "b"=>2, "c"=>3)
        ~~~
        {{for (a,b) in v_1}}
            a: {{fill a}} b: {{fill b}}
        {{end}}
        ~~~
        """ |> fd2html_td
    @test isapproxstr(s, """
        a: a b: 1
        a: b b: 2
        a: c b: 3
        """)
end
