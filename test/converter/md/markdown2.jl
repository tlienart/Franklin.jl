# this follows `markdown.jl` but spurred by bugs/issues

function inter(st::String)
    steps = explore_md_steps(st)
    return steps[:inter_md].inter_md, steps[:inter_html].inter_html
end

@testset "issue163" begin
    st = raw"""A _B `C` D_ E"""
    imd, ih = inter(st)
    @test imd == "A _B  ##FDINSERT## D_ E"
    @test isapproxstr(ih, "<p>A <em>B  ##FDINSERT##  D</em> E</p>")

    st = raw"""A _`B` C D_ E"""
    imd, ih = inter(st)
    @test isapproxstr(imd, "A _ ##FDINSERT##  C D_ E")
    @test isapproxstr(ih, "<p>A <em>##FDINSERT##  C D</em> E</p>")

    st = raw"""A _B C `D`_ E"""
    imd, ih = inter(st)
    @test isapproxstr(imd, "A _B C  ##FDINSERT## _ E")
    @test isapproxstr(ih, "<p>A <em>B C  ##FDINSERT##</em> E</p>")

    st = raw"""A _`B` C `D`_ E"""
    imd, ih = inter(st)
    @test isapproxstr(imd, "A _ ##FDINSERT##  C  ##FDINSERT## _ E")
    @test isapproxstr(ih, "<p>A <em>##FDINSERT##  C  ##FDINSERT##</em> E</p>")
end

@testset "TOC"  begin
    fs()
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
            <li><a href="#hello_fd">Hello <code>fd</code></a>
              <ol>
                <li style="list-style-type: none;">
                  <ol>
                    <li><a href="#weirdly_nested">weirdly nested</a></li>
                  </ol>
                </li>
                <li><a href="#goodbye">Goodbye&#33;</a></li>
              </ol>
            </li>
            <li><a href="#done">Done</a></li>
          </ol>
        </div>
        <h2 id="hello_fd"><a href="#hello_fd" class="header-anchor">Hello <code>fd</code></a></h2>
        <h4 id="weirdly_nested"><a href="#weirdly_nested" class="header-anchor">weirdly nested</a></h4>
        <h3 id="goodbye"><a href="#goodbye" class="header-anchor">Goodbye&#33;</a></h3>
        <h2 id="done"><a href="#done" class="header-anchor">Done</a></h2>
        <p>done.</p>
        """)
end

@testset "TOC-2"  begin
    fs()
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
                <li><a href="#b">B</a>
                    <ol>
                        <li><a href="#d">D</a></li>
                    </ol>
                </li>
                <li><a href="#e">E</a>
                    <ol>
                        <li><a href="#f">F</a></li>
                    </ol>
                </li>
            </ol>
        </div>
        <h1 id="a"><a href="#a" class="header-anchor">A</a></h1>
        <h2 id="b"><a href="#b" class="header-anchor">B</a></h2>
        <h4 id="c"><a href="#c" class="header-anchor">C</a></h4>
        <h3 id="d"><a href="#d" class="header-anchor">D</a></h3>
        <h2 id="e"><a href="#e" class="header-anchor">E</a></h2>
        <h3 id="f"><a href="#f" class="header-anchor">F</a></h3>
        <p>done.</p>
        """)
end
