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
                <pre><code>A \ b</code></pre>
                done</p>
                """)
end
