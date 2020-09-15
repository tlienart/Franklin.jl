s = """Veggies es bonus vobis, proinde vos postulo essum magis kohlrabi welsh onion daikon amaranth tatsoi tomatillo melon azuki bean garlic.

Gumbo beet greens corn soko endive gumbo gourd. Parsley shallot courgette tatsoi pea sprouts fava bean collard greens dandelion okra wakame tomato. Dandelion cucumber earthnut pea peanut soko zucchini.

Turnip greens yarrow ricebean rutabaga endive cauliflower sea lettuce kohlrabi amaranth water spinach avocado daikon napa cabbage asparagus winter purslane kale.
Celery potato scallion desert raisin horseradish spinach carrot soko. Lotus root water spinach fennel kombu maize bamboo shoot green bean swiss chard seakale pumpkin onion chickpea gram corn pea. Brussels sprout coriander water chestnut gourd swiss chard wakame kohlrabi beetroot carrot watercress.
Corn amaranth salsify bunya nuts nori azuki bean chickweed potato bell pepper artichoke.
"""

@testset "context" begin
    mess = F.context(s, 101)
    @test s[101] == 't'
    # println(mess)
    @test mess == "Context:\n\t...ikon amaranth tatsoi tomatillo melon azuki ... (near line 1)\n	                        ^---\n"

    mess = F.context(s, 211)
    @test s[211] == 't'
    # println(mess)
    @test mess == "Context:\n\t...ey shallot courgette tatsoi pea sprouts fav... (near line 2)\n	                        ^---\n"

    mess = F.context(s, 10)
    # println(mess)
    @test mess == "Context:\n\tVeggies es bonus vobis, proinde... (near line 1)\n	         ^---\n"

    mess = F.context(s, 880)
    # println(mess)
    @test mess == "Context:\n\t... potato bell pepper artichoke. (near line 5)\n	                        ^---\n"
end

@testset "show" begin
    ocbe = F.OCBlockError("foo", "bar")
    io = IOBuffer()
    Base.showerror(io, ocbe)
    r = String(take!(io))
    @test r == "foo\nbar"

    mcbe = F.MathBlockError("foo")
    @test mcbe.m == "foo"
end

@testset "ocbe" begin
    s = raw"""
        Foo $$ end.
        """
    @test_throws F.OCBlockError s |> fd2html_td
end

@testset "lxbe" begin
    s = raw"""
        Foo
        \newcommand{\hello}
        End
        """
    @test_throws F.LxDefError s |> fd2html_td

    s = raw"""
        Foo
        \newcommand{\hello} {goodbye}
        \hello
        End
        """ |> fd2html_td
    @test isapproxstr(s, "<p>Foo</p><p>goodbye End</p>")

    s2 = raw"""
        Foo
        \newcommand{\hello}[ ]{goodbye}
        \hello
        End
        """ |> fd2html_td
    @test isapproxstr(s, s2)

    # should  fail XXX

    s2 = raw"""
        Foo
        \newcommand{\hello}b{goodbye}
        \hello
        End
        """
    @test_throws F.LxDefError s2 |> fd2html_td

    s2 = raw"""
        Foo
        \newcommand{\hello}b{goodbye #1}
        \hello{ccc}
        End
        """
    @test_throws F.LxDefError s2 |> fd2html_td

    s2 = raw"""
        Foo
        \newcommand{\hello}[bb]{goodbye #1}
        \hello{ccc}
        End
        """
    @test_throws F.LxDefError s2 |> fd2html_td

    # tolerated

    s2 = raw"""
        Foo
        \newcommand{\hello}  {goodbye}
        \hello
        End
        """ |> fd2html_td
    @test isapproxstr(s, s2)
end

@testset "Unfound" begin
    fs();
    @test_throws F.FileNotFoundError F.resolve_rpath("./foo")
end

@testset "H-For" begin
    s = """
        {{for x in blah}}
        foo
        """
    @test_throws F.HTMLBlockError s |> F.convert_html
    s = """
        @def list = [1,2,3]
        ~~~
        {{for x in list}}
        foo
        ~~~
        """
    @test_throws F.HTMLBlockError s |> fd2html_td
    s = """
        @def list = [1,2,3]
        ~~~
        {{for x in list2}}
        foo
        {{end}}
        ~~~
        """
    @test_throws F.HTMLBlockError s |> fd2html_td
    s = """
        @def list = [1,2,3]
        ~~~
        {{for x in list}}
        {{if a}}
        foo
        {{end}}
        ~~~
        """
    @test_throws F.HTMLBlockError s |> fd2html_td
end

@testset "HToc" begin
    s = """
        {{toc 1}}
        """
    @test_throws F.HTMLFunctionError s |> F.convert_html
    s = """
        ~~~
        {{toc aa bb}}
        ~~~
        # Hello
        """
    @test_throws F.HTMLFunctionError s |> fd2html_td
end
