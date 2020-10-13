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


@testset "Lx defs+coms" begin
    st = raw"""
        \newcommand{\E}[1]{\mathbb E\left[#1\right]}blah de blah
        ~~~
        escape b1
        ~~~
        \newcommand{\eqa}[1]{\begin{eqnarray}#1\end{eqnarray}}
        \newcommand{\R}{\mathbb R}
        Then something like
        \eqa{ \E{f(X)} \in \R &\text{if}& f:\R\maptso\R }
        and we could try to show latex:
        ```latex
        \newcommand{\brol}{\mathbb B}
        ```
        """ |> fd2html
    @test isapproxstr(st, raw"""
        <p>
          blah de blah
          escape b1
        </p>
        <p>
          Then something like
            \[\begin{array}{rcl}
              \mathbb E\left[ f(X)\right] \in \mathbb R &\text{if}& f:\mathbb R\maptso\mathbb R
            \end{array}\]
          and we could try to show latex:
        </p>
        <pre><code class="language-latex">
          \newcommand&#123;\brol&#125;&#123;\mathbb B&#125;
        </code></pre>
        """)
end


@testset "Lxdefs 2" begin
    st = raw"""
        \newcommand{\com}{blah}
        \newcommand{\comb}[ 2]{hello #1 #2}
        """

    lxdefs, tokens, braces, blocks, lxcoms = explore_md_steps(st)[:latex]

    @test lxdefs[1].name == "\\com"
    @test lxdefs[1].narg == 0
    @test lxdefs[1].def == "blah"
    @test lxdefs[2].name == "\\comb"
    @test lxdefs[2].narg == 2
    @test lxdefs[2].def == "hello #1 #2"

    #
    # Errors
    #

    # testing malformed newcommands
    st = raw"""abc \newcommand abc"""
    tokens = F.find_tokens(st, F.MD_TOKENS, F.MD_1C_TOKENS)
    blocks, tokens = F.find_all_ocblocks(tokens, F.MD_OCB_ALL)
    # Ill formed newcommand (needs two {...})
    @test_throws F.LxDefError F.find_lxdefs(tokens, blocks)
    st = raw"""abc \newcommand{abc} def"""
    tokens = F.find_tokens(st, F.MD_TOKENS, F.MD_1C_TOKENS)
    blocks, tokens = F.find_all_ocblocks(tokens, F.MD_OCB_ALL)
    # Ill formed newcommand (needs two {...})
    @test_throws F.LxDefError F.find_lxdefs(tokens, blocks)
end


@testset "Lxcoms 2" begin
    st = raw"""
        \newcommand{\com}{HH}
        \newcommand{\comb}[1]{HH#1HH}
        Blah \com and \comb{blah} etc
        ```julia
        f(x) = x^2
        ```
        etc \comb{blah} then maybe
        @@adiv inner part @@ final.
        """

    lxdefs, tokens, braces, blocks, lxcoms = explore_md_steps(st)[:latex]

    @test lxcoms[1].ss == "\\com"
    @test lxcoms[2].ss == "\\comb{blah}"

    @test blocks[1].name == :CODE_BLOCK_LANG
    @test blocks[1].ss == "```julia\nf(x) = x^2\n```"
    @test F.content(blocks[1]) == "\nf(x) = x^2\n"

    @test blocks[2].name == :DIV
    @test blocks[2].ss == "@@adiv inner part @@"
    @test F.content(blocks[2]) == " inner part "

    #
    # Errors
    #

    st = raw"""
        \newcommand{\comb}[1]{HH#1HH}
        etc \comb then.
        """

    tokens = F.find_tokens(st, F.MD_TOKENS, F.MD_1C_TOKENS)
    blocks, tokens = F.find_all_ocblocks(tokens, F.MD_OCB_ALL)
    lxdefs, tokens, braces, blocks = F.find_lxdefs(tokens, blocks)
    # Command comb expects 1 argument and there should be no spaces ...
    @test_throws F.LxComError F.find_lxcoms(tokens, lxdefs, braces)
end


@testset "lxcoms3" begin
    st = raw"""
        text A1 \newcommand{\com}{blah}text A2 \com and
        ~~~
        escape B1
        ~~~
        \newcommand{\comb}[ 1]{\mathrm{#1}} text C1 $\comb{b}$ text C2
        \newcommand{\comc}[ 2]{part1:#1 and part2:#2} then \comc{AA}{BB}.
        """

    lxdefs, tokens, braces, blocks, lxcoms = explore_md_steps(st)[:latex]

    @test lxdefs[1].name == "\\com" && lxdefs[1].narg == 0 &&  lxdefs[1].def == "blah"
    @test lxdefs[2].name == "\\comb" && lxdefs[2].narg == 1 && lxdefs[2].def == "\\mathrm{#1}"
    @test lxdefs[3].name == "\\comc" && lxdefs[3].narg == 2 && lxdefs[3].def == "part1:#1 and part2:#2"
    @test blocks[1].name == :ESCAPE
    @test blocks[1].ss == "~~~\nescape B1\n~~~"
end


@testset "Merge-blocks" begin
    st = raw"""
        @def title = "Convex Optimisation I"
        \newcommand{\com}[1]{⭒!#1⭒}
        \com{A}
        <!-- comment -->
        then some
        ## blah <!-- ✅ 19/9/999 -->
        end \com{B}.
        """

    lxdefs, tokens, braces, blocks, lxcoms = explore_md_steps(st)[:latex]

    @test blocks[1].name == :MD_DEF
    @test F.content(blocks[1]) == " title = \"Convex Optimisation I\""
    @test blocks[2].name == :COMMENT
    @test F.content(blocks[2]) == " comment "
    @test blocks[3].name == :H2
    @test F.content(blocks[3]) == " blah <!-- ✅ 19/9/999 -->"

    @test lxcoms[1].ss == "\\com{A}"
    @test lxcoms[2].ss == "\\com{B}"

    b2i = F.merge_blocks(lxcoms, blocks)

    @test b2i[1].ss == "@def title = \"Convex Optimisation I\"\n"
    @test b2i[2].ss == "\\com{A}"
    @test b2i[3].ss == "<!-- comment -->"
    @test b2i[4].ss == "## blah <!-- ✅ 19/9/999 -->\n"
    @test b2i[5].ss == "\\com{B}"
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
        <h1 id="t1"><a href="#t1">t1</a></h1>
        <p>1</p>
        <h2 id="t2"><a href="#t2">t2</a></h2>
        <p>2</p>
        <h2 id="t3_blah_etc"><a href="#t3_blah_etc">t3 <code>blah</code> etc</a></h2>
        <p>3</p>
        <h3 id="t4"><a href="#t4">t4 </a></h3>
        <p>4</p>
        <h3 id="t2__2"><a href="#t2__2">t2</a></h3>
        <p>5</p>
        <h3 id="t2__3"><a href="#t2__3">t2</a></h3>
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
        <h2 id="example"><a href="#example">example</a></h2>
        <p>A</p>
        <h2 id="example__2"><a href="#example__2">example</a></h2>
        <p>B</p>
        <h2 id="example_2"><a href="#example_2">example 2</a></h2>
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
    @test h // """<h1 id="blah"><a href="#blah">blah</a></h1>"""
    h = raw"""
        \newcommand{\foo}{foo}
        \newcommand{\header}{# hello}
        \foo
        \header
        """ |> fd2html_td
    @test h // """<p>foo <h1 id="hello"><a href="#hello">hello</a></h1></p>"""
    h = raw"""
        \newcommand{\foo}{foo}
        \foo hello
        """ |> fd2html_td
    @test h // """<p>foo hello</p>"""
    h = raw"""
        \newcommand{\foo}{blah}
        # \foo hello
        """ |> fd2html_td
    @test h // """<h1 id="blah_hello"><a href="#blah_hello">blah hello</a></h1>"""
    h = raw"""
        \newcommand{\foo}{foo}
        \newcommand{\header}[2]{!#1 \foo #2}
        \header{##}{hello}
        """ |> fd2html_td
    @test h // """<h2 id="foo_hello"><a href="#foo_hello">foo  hello</a></h2>"""
end
