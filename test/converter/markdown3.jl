# NOTE: theses tests focus on speciall characters, html entities
# escaping things etc.

@testset "Backslashes" begin # see issue #205
    st = raw"""
        Hello \ blah \ end
        and `B \ c` end and
        ```
        A \ b
        ```
        done
        """ * J.EOS

    steps = explore_md_steps(st)
    tokens, = steps[:tokenization]

    # the first two backspaces are detected
    @test tokens[1].ss == "\\" && tokens[1].name == :CHAR_BACKSPACE
    @test tokens[2].ss == "\\" && tokens[2].name == :CHAR_BACKSPACE
    # the third one also
    @test tokens[5].ss == "\\" && tokens[5].name == :CHAR_BACKSPACE

    sp_chars, = steps[:spchars]

    # there's only two tokens left which are the backspaces NOT in the code env
    sp_chars = J.find_special_chars(tokens)
    for i in 1:2
        @test sp_chars[i] isa J.HTML_SPCH
        @test sp_chars[i].ss == "\\"
        @test sp_chars[i].r == "&#92;"
    end

    inter_html, = steps[:inter_html]

    @test isapproxstr(inter_html, "<p>Hello  ##JDINSERT##  blah  ##JDINSERT##  end and  ##JDINSERT##  end and  ##JDINSERT##  done</p>")

    @test isapproxstr(st |> seval, raw"""
                <p>Hello &#92; blah &#92; end
                and <code>B \ c</code> end and
                <pre><code class="language-julia">A \ b</code></pre>
                done</p>
                """)
end

@testset "Backslashes2" begin # see issue #205
    st = raw"""
        Hello \ blah \ end
        and `B \ c` end \\ and
        ```
        A \ b
        ```
        done
        """ * J.EOS
    steps = explore_md_steps(st)
    tokens, = steps[:tokenization]
    @test tokens[7].name == :CHAR_LINEBREAK
    h = st |> seval
    @test isapproxstr(st |> seval, raw"""
                        <p>Hello &#92; blah &#92; end
                        and <code>B \ c</code> end <br/> and
                        <pre><code class="language-julia">A \ b</code></pre>
                        done</p>
                        """)
end

@testset "Backtick" begin # see issue #205
    st = raw"""Blah \` etc""" * J.EOS
    @test isapproxstr(st |> seval, "<p>Blah &#96; etc</p>")
end

@testset "HTMLEnts" begin # see issue #206
    st = raw"""Blah &pi; etc""" * J.EOS
    @test isapproxstr(st |> seval, "<p>Blah &pi; etc</p>")
    # but ill-formed ones (either deliberately or not) will be parsed
    st = raw"""AT&T""" * J.EOS
    @test isapproxstr(st |> seval, "<p>AT&amp;T</p>")
end

@testset "DoubleTicks" begin # see issue #204
    st = raw"""A `single` B""" * J.EOS
    steps = explore_md_steps(st)
    tokens = steps[:tokenization].tokens
    @test tokens[1].name == :CODE_SINGLE
    @test tokens[2].name == :CODE_SINGLE

    st = raw"""A ``double`` B""" * J.EOS
    steps = explore_md_steps(st)
    tokens = steps[:tokenization].tokens
    @test tokens[1].name == :CODE_DOUBLE
    @test tokens[2].name == :CODE_DOUBLE

    st = raw"""A `single` and ``double`` B""" * J.EOS
    steps = explore_md_steps(st)
    tokens = steps[:tokenization].tokens
    @test tokens[1].name == :CODE_SINGLE
    @test tokens[2].name == :CODE_SINGLE
    @test tokens[3].name == :CODE_DOUBLE
    @test tokens[4].name == :CODE_DOUBLE

    st = raw"""A `single` and ``double ` double`` B""" * J.EOS
    steps = explore_md_steps(st)
    blocks, tokens = steps[:ocblocks]
    @test blocks[1].name == :CODE_INLINE
    @test J.content(blocks[1]) == "double ` double"
    @test blocks[2].name == :CODE_INLINE
    @test J.content(blocks[2]) == "single"

    st = raw"""A `single` and ``double ` double`` and ``` triple ``` B""" * J.EOS
    steps = explore_md_steps(st)
    tokens = steps[:tokenization].tokens
    @test tokens[1].name == :CODE_SINGLE
    @test tokens[2].name == :CODE_SINGLE
    @test tokens[3].name == :CODE_DOUBLE
    @test tokens[4].name == :CODE_SINGLE
    @test tokens[5].name == :CODE_DOUBLE
    @test tokens[6].name == :CODE_TRIPLE
    @test tokens[7].name == :CODE_TRIPLE
    blocks, tokens = steps[:ocblocks]
    @test blocks[1].name == :CODE_BLOCK
    @test J.content(blocks[1]) == " triple "
    @test blocks[2].name == :CODE_INLINE
    @test blocks[3].name == :CODE_INLINE

    st = raw"""A `single` and ``double ` double`` and ``` triple `` triple```
               and ```julia 1+1``` and `single again` done""" * J.EOS
    steps = explore_md_steps(st)
    blocks, _ = steps[:ocblocks]
    @test blocks[1].name == :CODE_BLOCK_LANG
    @test J.content(blocks[1]) == " 1+1"
    @test blocks[2].name == :CODE_BLOCK
    @test J.content(blocks[2]) == " triple `` triple"
    @test blocks[3].name == :CODE_INLINE
    @test J.content(blocks[3]) == "double ` double"
    @test blocks[4].name == :CODE_INLINE
    @test J.content(blocks[4]) == "single"
end

@testset "\\ and \`" begin # see issue 203
    st = raw"""The `"Hello\n"` after the `readall` command is a returned value, whereas the `Hello` after the `run` command is printed output.""" * J.EOS
    st |> seval
    @test isapproxstr(st |> seval, raw"""
                        <p>The <code>&quot;Hello\n&quot;</code> after
                        the <code>readall</code> command is a returned value,
                        whereas the <code>Hello</code> after the <code>run</code>
                        command is printed output.</p>""")
end


@testset "i198" begin
    st = raw"""
            Essentially three things are imitated from LaTeX
            1. you can introduce definitions using `\newcommand`
            1. you can use hyper-references with `\eqref`, `\cite`, ...
            1. you can show nice maths (via KaTeX)
            """ * J.EOS

    @test isapproxstr(st |> seval, raw"""
                    <p>Essentially three things are imitated from LaTeX</p>
                    <ol>
                        <li><p>you can introduce definitions using <code>\newcommand</code></p></li>
                        <li><p>you can use hyper-references with <code>\eqref</code>, <code>\cite</code>, ...</p></li>
                        <li><p>you can show nice maths &#40;via KaTeX&#41;</p></li>
                    </ol>
                    """)
end


@testset "fixlinks" begin
   st = raw"""
        A [link] and
        B [link 2] and
        C [Python][] and
        D [a link][1] and
        blah
        [link]: https://julialang.org/
        [link 2]: https://www.mozilla.org/
        [Python]: https://www.python.org/
        [1]: http://slashdot.org/
        end
        """ * J.EOS
    @test isapproxstr(st |> seval, """
                        <p>
                            A <a href=\"https://julialang.org/\">link</a> and
                            B <a href=\"https://www.mozilla.org/\">link 2</a> and
                            C <a href=\"https://www.python.org/\"title=\"Python\">Python</a> and
                            D <a href=\"http://slashdot.org/\">a link</a> and
                            blah
                            end
                         </p>""")
end


@testset "fixlinks2" begin
    st = raw"""
        A [link] and
        B ![link][id] and
        blah
        [link]: https://julialang.org/
        [id]: ./path/to/img.png
        """ * J.EOS

    @test isapproxstr(st |> seval, """
                      <p>
                          A <a href="https://julialang.org/">link</a> and
                          B <img src="./path/to/img.png" alt="link"> and
                          blah
                      </p>""")
end


@testset "fixlinks3" begin
    st = raw"""
        A [link] and
        B [unknown] and
        C ![link][id] and
        D
        [link]: https://julialang.org/
        [id]: ./path/to/img.png
        [not]: https://www.mozilla.org/
        """ * J.EOS

    @test isapproxstr(st |> seval, """
                      <p>
                        A <a href="https://julialang.org/">link</a> and
                        B &#91;unknown&#93; and
                        C <img src="./path/to/img.png" alt="link"> and
                        D
                      </p>""")
end


@testset "IndCode" begin # issue 207
    st = raw"""
        A
            a = 1+1
            if a > 1
                @show a
            end
            b = 2
            @show a+b
        end
        """ * J.EOS
    @test isapproxstr(st |> seval, raw"""
                        <p>
                        A
                        <pre><code class="language-julia">
                        a &#61; 1&#43;1
                        if a &gt; 1
                            @show a
                        end
                        b &#61; 2
                        @show a&#43;b
                        </code></pre>
                        end
                        </p>
                        """)

    st = raw"""
        A `single` and ```python blah``` and
            a = 1+1
        then
        * blah
            + blih
            + bloh
        end
        """ * J.EOS
    @test isapproxstr(st |> seval, raw"""
                        <p>
                        A <code>single</code> and
                        <pre><code class="language-python">
                        blah
                        </code></pre>
                        and
                        <pre><code class="language-julia">
                        a &#61; 1&#43;1
                        </code></pre>
                        then</p>
                        <ul>
                          <li><p>blah</p>
                            <ul>
                              <li><p>blih</p></li>
                              <li><p>bloh</p></li>
                            </ul>
                          </li>
                        </ul>
                        <p>end</p>
                        """)

    st = raw"""
        A

            function foo()

                return 2

            end

            function bar()
                return 3
            end

        B

            function baz()
                return 5

            end

        C
        """ * J.EOS
    isapproxstr(st |> seval, raw"""
                            <p>A <pre><code class="language-julia">function foo()

                                return 2

                            end

                            function bar()
                                return 3
                            end</code></pre>
                            B <pre><code class="language-julia">function baz()
                                return 5

                            end</code></pre>
                            C</p>
                            """)
end


@testset "More ``" begin
    st = raw"""
         A ``blah``.
         """ * J.EOS
    isapproxstr(st |> seval, """<p>A <code>blah</code>.</p>""")
end
