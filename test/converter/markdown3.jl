@testset "Backslashes" begin # see issue #205
    st = raw"""
        Hello \ blah \ end
        and `B \ c` end and
        ```
        A \ b
        ```
        done
        """ * J.EOS
    tokens = J.find_tokens(st, J.MD_TOKENS, J.MD_1C_TOKENS)

    # the first two backspaces are detected
    @test tokens[1].ss == "\\" && tokens[1].name == :CHAR_BACKSPACE
    @test tokens[2].ss == "\\" && tokens[2].name == :CHAR_BACKSPACE
    # the third one also
    @test tokens[5].ss == "\\" && tokens[5].name == :CHAR_BACKSPACE

    blocks, tokens = J.find_all_ocblocks(tokens, J.MD_OCB_ALL)
    filter!(τ -> τ.name != :LINE_RETURN, tokens)

    # there's only two tokens left which are the backspaces NOT in the code env
    sp_chars = J.find_special_chars(tokens)
    for i in 1:2
        @test sp_chars[i] isa J.HTML_SPCH
        @test sp_chars[i].ss == "\\"
        @test sp_chars[i].r == "&#92;"
    end

    blocks2insert = J.merge_blocks(blocks, sp_chars)
    inter_md, mblocks = J.form_inter_md(st, blocks2insert, J.LxDef[])
    inter_html = J.md2html(inter_md)

    @test isapproxstr(inter_html, "<p>Hello  ##JDINSERT##  blah  ##JDINSERT##  end and  ##JDINSERT##  end and  ##JDINSERT##  done</p>")

    @test isapproxstr(st |> seval, raw"""
                <p>Hello &#92; blah &#92; end
                and <code>B \ c</code> end and
                <pre><code>A \ b</code></pre>
                done</p>
                """)
end
