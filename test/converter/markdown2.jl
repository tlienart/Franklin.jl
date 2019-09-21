# this follows `markdown.jl` but spurred by bugs/issues

function inter(st::String)
    steps = explore_md_steps(st)
    return steps[:inter_md].inter_md, steps[:inter_html].inter_html
end

@testset "issue163" begin
    st = raw"""A _B `C` D_ E""" * J.EOS
    imd, ih = inter(st)
    @test imd == "A _B  ##JDINSERT##  D_ E"
    @test ih == "<p>A <em>B  ##JDINSERT##  D</em> E</p>\n"

    st = raw"""A _`B` C D_ E""" * J.EOS
    imd, ih = inter(st)
    @test imd == "A _ ##JDINSERT##  C D_ E"
    @test ih == "<p>A <em>##JDINSERT##  C D</em> E</p>\n"

    st = raw"""A _B C `D`_ E""" * J.EOS
    imd, ih = inter(st)
    @test imd == "A _B C  ##JDINSERT## _ E"
    @test ih == "<p>A <em>B C  ##JDINSERT##</em> E</p>\n"

    st = raw"""A _`B` C `D`_ E""" * J.EOS
    imd, ih = inter(st)
    @test imd == "A _ ##JDINSERT##  C  ##JDINSERT## _ E"
    @test ih == "<p>A <em>##JDINSERT##  C  ##JDINSERT##</em> E</p>\n"
end


@testset "TOC"  begin
    J.CUR_PATH[] = "pages/ff/aa.md"
    h = raw"""
        \toc
        ## Hello `jd`
        ### Goodbye!
        ## Done
        done.
        """ * J.EOS |> seval
    @test isapproxstr(h, raw"""
        <div class="jd-toc">
          <ol>
            <ol>
              <li><a href="/pub/ff/aa.html#hello_jd">Hello <code>jd</code></a></li>
              <ol>
                <li><a href="/pub/ff/aa.html#goodbye">Goodbye&#33;</a></li>
              </ol>
              <li><a href="/pub/ff/aa.html#done">Done</a></li>
            </ol>
          </ol>
        </div>
        <h2 id="hello_jd"><a href="/pub/ff/aa.html#hello_jd">Hello <code>jd</code></a></h2>
        <h3 id="goodbye"><a href="/pub/ff/aa.html#goodbye">Goodbye&#33;</a></h3>
        <h2 id="done"><a href="/pub/ff/aa.html#done">Done</a></h2>done.
        """)
end
