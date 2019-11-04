@testset "Bold x*" begin # issue 223
    h = raw"**x\***" * J.EOS |> seval
    @test h == "<p><strong>x&#42;</strong></p>\n"

    h = raw"_x\__" * J.EOS |> seval
    @test h == "<p><em>x&#95;</em></p>\n"
end

@testset "Bold code" begin # issue 222
    h = raw"""A **`master`** B.""" * J.EOS |> seval
    @test h == "<p>A <strong><code>master</code></strong> B.</p>\n"
end

@testset "Tickssss" begin # issue 219
    st = raw"""A `B` C""" * J.EOS
    tokens = J.find_tokens(st, J.MD_TOKENS, J.MD_1C_TOKENS)
    @test tokens[1].name == :CODE_SINGLE
    @test tokens[2].name == :CODE_SINGLE

    st = raw"""A ``B`` C""" * J.EOS
    tokens = J.find_tokens(st, J.MD_TOKENS, J.MD_1C_TOKENS)
    @test tokens[1].name == :CODE_DOUBLE
    @test tokens[2].name == :CODE_DOUBLE

    st = raw"""A ``` B ``` C""" * J.EOS
    tokens = J.find_tokens(st, J.MD_TOKENS, J.MD_1C_TOKENS)
    @test tokens[1].name == :CODE_TRIPLE
    @test tokens[2].name == :CODE_TRIPLE

    st = raw"""A ````` B ````` C""" * J.EOS
    tokens = J.find_tokens(st, J.MD_TOKENS, J.MD_1C_TOKENS)
    @test tokens[1].name == :CODE_PENTA
    @test tokens[2].name == :CODE_PENTA

    st = raw"""A ```b B ``` C""" * J.EOS
    tokens = J.find_tokens(st, J.MD_TOKENS, J.MD_1C_TOKENS)
    @test tokens[1].name == :CODE_LANG
    @test tokens[2].name == :CODE_TRIPLE

    st = raw"""A `````b B ````` C""" * J.EOS
    tokens = J.find_tokens(st, J.MD_TOKENS, J.MD_1C_TOKENS)
    @test tokens[1].name == :CODE_LANG2
    @test tokens[2].name == :CODE_PENTA

    h = raw"""
        A
        `````markdown
        B
        `````
        C
        """ |> jd2html_td

    @test isapproxstr(h, raw"""
            <p>A
            <pre><code class="language-markdown">B
            </code></pre> C</p>
            """)

    h = raw"""
        A
        `````markdown
        ```julia
        B
        ```
        `````
        C
        """ |> jd2html_td

    @test isapproxstr(h, raw"""
            <p>A
            <pre><code class="language-markdown">```julia
            B
            ```
            </code></pre> C</p>
            """)
end

@testset "Nested ind" begin # issue 285
    h = raw"""
    \newcommand{\hello}{
        yaya
        bar bar
    }
    \hello
    """ |> jd2html_td
    @test isapproxstr(h, raw"""yaya  bar bar""")
    h = raw"""
    @@da
        @@db
            @@dc
                blah
            @@
        @@
    @@
    """ |> jd2html_td
    @test isapproxstr(h, raw"""
            <div class="da">
                <div class="db">
                    <div class="dc">
                        blah
                    </div>
                </div>
            </div>
            """)
    h = raw"""
    \newcommand{\hello}[1]{#1}
    \hello{
        good lord
    }
    """ |> jd2html_td
    @test isapproxstr(h, "good lord")
end
