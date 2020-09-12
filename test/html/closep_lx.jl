#= NOTE:

- general rule: use latex command for either block or inline, avoid mixing (1, 2, 3)
- if a command defines a block, use empty lines to separate otherwise it will be plugged in a paragraph (3)
- if mixing inline and block, you may get unexpected stuff
    - ok (4.a)
    - nok (4.b)
- nesting (5)
=#

@testset "1/noblock nop" begin
    h = raw"""
        \newcommand{\foo}{A **B** C}
        1 \foo 2
        """ |> fd2html
    @test h // "<p>1 A <strong>B</strong> C 2</p>"
end

@testset "2/block nop" begin
    h = raw"""
        \newcommand{\foo}{```julia
        x = 5
        @show x
        ```}
        1 \foo 2
        """ |> fd2html
    @test h // """<p>1 <pre><code class="language-julia">$(F.htmlesc(raw"""x = 5
                  @show x"""))</code></pre> 2</p>"""
end

@testset "3/block wp" begin
    h = raw"""
        \newcommand{\foo}{```julia
        x = 5
        @show x
        ```}
        1

        \foo

        2""" |> fd2html
    @test h // """<p>1</p>
                  <pre><code class="language-julia">$(F.htmlesc(raw"""x = 5
                  @show x"""))</code></pre>
                  <p>2</p>"""
end

@testset "4/mixing" begin
    # OK (4.a)
    h = raw"""
        \newcommand{\foo}{A $$ x = 5 $$ B}
        1 \foo 2
        """ |> fd2html
    @test h // raw"""
               <p>1 A </p>
               \[ x = 5 \]
               <p>B 2</p>
               """
    # XXX NOK (4.b)
    h = raw"""
       \newcommand{\foo}{A $$ x = 5 $$ B}
       1

       \foo

       2
       """ |> fd2html
    @test h // raw"""
               <p>1</p>
               A </p>
               \[ x = 5 \]
               <p>B
               <p>2</p>"""
end

@testset "5/nesting" begin
    h = raw"""
        \newcommand{\foo}{A `B` C}
        \newcommand{\bar}{1 \foo 2}
        aa \bar bb
        """ |> fd2html
    @test h // "<p>aa 1 A <code>B</code> C 2 bb</p>"
    h = raw"""
        \newcommand{\foo}[1]{@@b #1 @@}
        \newcommand{\bar}[1]{A `!#1` \foo{g} C}
        aa \bar{hh} bb
        """ |> fd2html
    @test h // """
               <p>aa A <code>hh</code> <div class="b">g</div> C bb</p>
               """
    # nesting with block // mixing
    h = raw"""
        \newcommand{\foo}[1]{```python
        !#1
        ```}
        \newcommand{\bar}[1]{ABC \foo{!#1} DEF}
        aa \bar{x=1} bb
        """ |> fd2html
    @test h // """
               <p>aa ABC <pre><code class="language-python">$(F.htmlesc(raw"""x=1"""))</code></pre> DEF bb</p>
               """
end

@testset "6/div-mix" begin
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
        <div class="note">
          <p>A </p>
          <div class="cc">B</div>
          <p>D</p>
        </div>
        <div class="note">
          <p>A </p>
          <div class="cc">B <code>D</code> E</div>
          <p>F</p>
        </div>
        """)
end
