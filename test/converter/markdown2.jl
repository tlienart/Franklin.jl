# this follows `markdown.jl` but spurred by bugs/issues

function inter(st::String)
    steps = explore_md_steps(st)
    return steps[:inter_md].inter_md, steps[:inter_html].inter_html
end

@testset "issue163" begin
    st = raw"""A _B `C` D_ E"""
    imd, ih = inter(st)
    @test imd == "A _B  ##FDINSERT##  D_ E"
    @test ih == "<p>A <em>B  ##FDINSERT##  D</em> E</p>\n"

    st = raw"""A _`B` C D_ E"""
    imd, ih = inter(st)
    @test imd == "A _ ##FDINSERT##  C D_ E"
    @test ih == "<p>A <em>##FDINSERT##  C D</em> E</p>\n"

    st = raw"""A _B C `D`_ E"""
    imd, ih = inter(st)
    @test imd == "A _B C  ##FDINSERT## _ E"
    @test ih == "<p>A <em>B C  ##FDINSERT##</em> E</p>\n"

    st = raw"""A _`B` C `D`_ E"""
    imd, ih = inter(st)
    @test imd == "A _ ##FDINSERT##  C  ##FDINSERT## _ E"
    @test ih == "<p>A <em>##FDINSERT##  C  ##FDINSERT##</em> E</p>\n"
end


@testset "TOC"  begin
    fs1()
    h = raw"""
        @def fd_rpath = "pages/ff/aa.md"
        \toc
        ## Hello `fd`
        #### weirdly nested
        ### Goodbye!
        ## Done
        done.
        """ |> seval
    @test isapproxstr(h, raw"""
        <div class="franklin-toc">
          <ol>
            <li>
              <a href="/pub/ff/aa.html#hello_fd">Hello <code>fd</code></a>
              <ol>
                <li><ol><li><a href="/pub/ff/aa.html#weirdly_nested">weirdly nested</a></li></ol></li>
                <li><a href="/pub/ff/aa.html#goodbye">Goodbye&#33;</a></li>
              </ol>
            </li>
            <li><a href="/pub/ff/aa.html#done">Done</a></li>
          </ol>
        </div>
        <h2 id="hello_fd"><a href="/pub/ff/aa.html#hello_fd">Hello <code>fd</code></a></h2>
        <h4 id="weirdly_nested"><a href="/pub/ff/aa.html#weirdly_nested">weirdly nested</a></h4>
        <h3 id="goodbye"><a href="/pub/ff/aa.html#goodbye">Goodbye&#33;</a></h3>
        <h2 id="done"><a href="/pub/ff/aa.html#done">Done</a></h2>done.
        """)
end

@testset "TOC"  begin
    fs1()
    s = raw"""
        @def fd_rpath = "pages/ff/aa.md"
        @def mintoclevel = 2
        @def maxtoclevel = 3
        \toc
        # A
        ## B
        #### C
        ### D
        ## E
        ### F
        done.
        """ |> seval
    @test isapproxstr(s, raw"""
        <div class="franklin-toc">
            <ol>
                <li><a href="/pub/ff/aa.html#b">B</a>
                    <ol>
                        <li><a href="/pub/ff/aa.html#d">D</a></li>
                    </ol>
                </li>
                <li><a href="/pub/ff/aa.html#e">E</a>
                    <ol>
                        <li><a href="/pub/ff/aa.html#f">F</a></li>
                    </ol>
                </li>
            </ol>
        </div>
        <h1 id="a"><a href="/pub/ff/aa.html#a">A</a></h1>
        <h2 id="b"><a href="/pub/ff/aa.html#b">B</a></h2>
        <h4 id="c"><a href="/pub/ff/aa.html#c">C</a></h4>
        <h3 id="d"><a href="/pub/ff/aa.html#d">D</a></h3>
        <h2 id="e"><a href="/pub/ff/aa.html#e">E</a></h2>
        <h3 id="f"><a href="/pub/ff/aa.html#f">F</a></h3> done.
        """)
end

@testset "TOC-fs2"  begin
    fs2()
    h = raw"""
        @def fd_rpath = "pages/ff/aa.md"
        \toc
        ## Hello `fd`
        #### weirdly nested
        ### Goodbye!
        ## Done
        done.
        """ |> seval
    @test isapproxstr(h, raw"""
        <div class="franklin-toc">
          <ol>
            <li>
              <a href="/pages/ff/aa/index.html#hello_fd">Hello <code>fd</code></a>
              <ol>
                <li><ol><li><a href="/pages/ff/aa/index.html#weirdly_nested">weirdly nested</a></li></ol></li>
                <li><a href="/pages/ff/aa/index.html#goodbye">Goodbye&#33;</a></li>
              </ol>
            </li>
            <li><a href="/pages/ff/aa/index.html#done">Done</a></li>
          </ol>
        </div>
        <h2 id="hello_fd"><a href="/pages/ff/aa/index.html#hello_fd">Hello <code>fd</code></a></h2>
        <h4 id="weirdly_nested"><a href="/pages/ff/aa/index.html#weirdly_nested">weirdly nested</a></h4>
        <h3 id="goodbye"><a href="/pages/ff/aa/index.html#goodbye">Goodbye&#33;</a></h3>
        <h2 id="done"><a href="/pages/ff/aa/index.html#done">Done</a></h2>done.
        """)
end

@testset "TOC-fs2"  begin
    fs2()
    s = raw"""
        @def fd_rpath = "pages/ff/aa.md"
        @def mintoclevel = 2
        @def maxtoclevel = 3
        \toc
        # A
        ## B
        #### C
        ### D
        ## E
        ### F
        done.
        """ |> seval
    @test isapproxstr(s, raw"""
        <div class="franklin-toc">
            <ol>
                <li><a href="/pages/ff/aa/index.html#b">B</a>
                    <ol>
                        <li><a href="/pages/ff/aa/index.html#d">D</a></li>
                    </ol>
                </li>
                <li><a href="/pages/ff/aa/index.html#e">E</a>
                    <ol>
                        <li><a href="/pages/ff/aa/index.html#f">F</a></li>
                    </ol>
                </li>
            </ol>
        </div>
        <h1 id="a"><a href="/pages/ff/aa/index.html#a">A</a></h1>
        <h2 id="b"><a href="/pages/ff/aa/index.html#b">B</a></h2>
        <h4 id="c"><a href="/pages/ff/aa/index.html#c">C</a></h4>
        <h3 id="d"><a href="/pages/ff/aa/index.html#d">D</a></h3>
        <h2 id="e"><a href="/pages/ff/aa/index.html#e">E</a></h2>
        <h3 id="f"><a href="/pages/ff/aa/index.html#f">F</a></h3> done.
        """)
end
