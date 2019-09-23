@testset "footnotes" begin
    st = """
        A[^1] B[^blah] C
        """ * J.EOS
    @test isapproxstr(st |> seval, """
           <p>A<sup id="fnref:1"><a href="#fndef:1" class="footnote-ref">[1]</a></sup>
              B<sup id="fnref:blah"><a href="#fndef:blah" class="footnote-ref">[2]</a></sup>
              C</p>""")
    st = """
        A[^1] B[^blah]
        C
        [^1]: first footnote
        [^blah]: second footnote
        """ * J.EOS
    @test isapproxstr(st |> seval, """
            <p>
                A<sup id="fnref:1"><a href="#fndef:1" class="footnote-ref">[1]</a></sup>
                B<sup id="fnref:blah"><a href="#fndef:blah" class="footnote-ref">[2]</a></sup>
                C
                <table class="footnote-def" id="fndef:1">
                    <tr>
                        <td><a href="#fnref:1" class="footnote-backref">[1]</a>
                        <td><span class="footnote-def-body"> first footnote</span></td>
                    </tr>
                </table>
                <table class="footnote-def" id="fndef:blah">
                    <tr>
                        <td><a href="#fnref:blah" class="footnote-backref">[2]</a>
                        <td><span class="footnote-def-body"> second footnote</span></td>
                    </tr>
                </table>
            </p>""")
end
