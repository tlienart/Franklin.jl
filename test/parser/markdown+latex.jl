@testset "Find Tokens" begin
    a = raw"""some markdown then `code` and @@dname block @@"""

    tokens = F.find_tokens(a, F.MD_TOKENS, F.MD_1C_TOKENS)

    @test tokens[1].name == :CODE_SINGLE
    @test tokens[2].name == :CODE_SINGLE
    @test tokens[3].name == :DIV_OPEN
    @test tokens[3].ss == "@@dname"
    @test tokens[4].ss == "@@"
    @test tokens[5].name == :EOS
end

@testset "Find blocks" begin
    st = raw"""
        some markdown then `code` and
        @@dname block @@
        then maybe an escape
        ~~~
        escape block
        ~~~
        and done {target} done.
        """

    steps = explore_md_steps(st)
    blocks, tokens = steps[:ocblocks]

    # inline code block
    β = blocks[1]
    @test β.name == :CODE_INLINE
    @test β.ss == "`code`"

    # div block
    β = blocks[2]
    @test β.name == :DIV
    @test β.ss == "@@dname block @@"

    # escape block
    β = blocks[3]
    @test β.name == :ESCAPE
    @test β.ss == "~~~\nescape block\n~~~"

    # escape block
    β = blocks[4]
    @test β.name == :LXB
    @test β.ss == "{target}"
end


@testset "Unicode lx" begin
    st = raw"""
    Call me “$x$”, not $🍕$.
    """

    steps = explore_md_steps(st)
    blocks, _ = steps[:ocblocks]

    # first math block
    β = blocks[1]
    @test β.name == :MATH_A
    @test β.ss == "\$x\$"

    # second math block
    β = blocks[2]
    @test β.name == :MATH_A
    @test β.ss == "\$🍕\$"
end

@testset "Header blocks" begin
    st = raw"""
        # t1
        1
        ## t2
        2 ## trick
        ### t3
        3
        #### t4
        4
        ##### t5
        5
        ###### t6
        6
        """

    tokens, blocks = explore_md_steps(st)[:filter]

    @test blocks[1].name == :H1
    @test blocks[2].name == :H2
    @test blocks[3].name == :H3
    @test blocks[4].name == :H4
    @test blocks[5].name == :H5
    @test blocks[6].name == :H6

    set_curpath("index.md")

    h = """
        # t1
        1
        ## t2
        2
        ## t3 `blah` etc
        3
        ### t4 <!-- title -->
        4
        ### t2
        5
        ### t2
        6
        """ |> seval
    @test isapproxstr(h, """
        <h1 id="t1"><a href="#t1" class="header-anchor">t1</a></h1>
        <p>1</p>
        <h2 id="t2"><a href="#t2" class="header-anchor">t2</a></h2>
        <p>2</p>
        <h2 id="t3_blah_etc"><a href="#t3_blah_etc" class="header-anchor">t3 <code>blah</code> etc</a></h2>
        <p>3</p>
        <h3 id="t4"><a href="#t4" class="header-anchor">t4 </a></h3>
        <p>4</p>
        <h3 id="t2__2"><a href="#t2__2" class="header-anchor">t2</a></h3>
        <p>5</p>
        <h3 id="t2__3"><a href="#t2__3" class="header-anchor">t2</a></h3>
        <p>6</p>
        """)

    # pathological issue 241
    h = raw"""
        ## example
        A
        ## example
        B
        ## example 2
        C
        """ |> seval
    @test  isapproxstr(h, """
        <h2 id="example"><a href="#example" class="header-anchor">example</a></h2>
        <p>A</p>
        <h2 id="example__2"><a href="#example__2" class="header-anchor">example</a></h2>
        <p>B</p>
        <h2 id="example_2"><a href="#example_2" class="header-anchor">example 2</a></h2>
        <p>C</p>
        """)
end

@testset "Line skip" begin
    h = raw"""
        Hello \\ goodbye
        """ |> seval
    @test isapproxstr(h, """<p>Hello <br/> goodbye</p>""")
end

@testset "Header+lx" begin
    h = "# blah" |> fd2html_td
    @test h // """<h1 id="blah"><a href="#blah" class="header-anchor">blah</a></h1>"""
    h = raw"""
        \newcommand{\foo}{foo}
        \newcommand{\header}{# hello}
        \foo
        \header
        """ |> fd2html_td
    @test h // """<p>foo <h1 id="hello"><a href="#hello" class="header-anchor">hello</a></h1></p>"""
    h = raw"""
        \newcommand{\foo}{foo}
        \foo hello
        """ |> fd2html_td
    @test h // """<p>foo hello</p>"""
    h = raw"""
        \newcommand{\foo}{blah}
        # \foo hello
        """ |> fd2html_td
    @test h // """<h1 id="blah_hello"><a href="#blah_hello" class="header-anchor">blah hello</a></h1>"""
    h = raw"""
        \newcommand{\foo}{foo}
        \newcommand{\header}[2]{!#1 \foo #2}
        \header{##}{hello}
        """ |> fd2html_td
    @test h // """<h2 id="foo_hello"><a href="#foo_hello" class="header-anchor">foo  hello</a></h2>"""
end
