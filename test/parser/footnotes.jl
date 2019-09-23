@testset "footnotes" begin
    J.CUR_PATH[] = "index.md"
    st = """
        A[^1] B[^blah] C
        """ * J.EOS
    @test isapproxstr(st |> seval, """
           <p>A<sup id="fnref:1"><a href="/index.html#fndef:1" class="fnref">[1]</a></sup>
              B<sup id="fnref:blah"><a href="/index.html#fndef:blah" class="fnref">[2]</a></sup>
              C</p>""")
    st = """
        A[^1] B[^blah]
        C
        [^1]: first footnote
        [^blah]: second footnote
        """ * J.EOS
    @test isapproxstr(st |> seval, """
            <p>
                A
                <sup id="fnref:1"><a href="/index.html#fndef:1" class="fnref">[1]</a></sup>
                B<sup id="fnref:blah"><a href="/index.html#fndef:blah" class="fnref">[2]</a></sup>
                C
                <table class="fndef" id="fndef:1">
                <tr>
                    <td class="fndef-backref"><a href="/index.html#fnref:1">[1]</a></td>
                    <td class="fndef-content">first footnote</td>
                </tr>
                </table>
                <table class="fndef" id="fndef:blah">
                    <tr>
                        <td class="fndef-backref"><a href="/index.html#fnref:blah">[2]</a></td>
                        <td class="fndef-content">second footnote</td>
                    </tr>
                </table>
            </p>""")
end
