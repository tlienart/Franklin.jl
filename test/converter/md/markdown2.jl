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
        @def mintoclevel = 1
        @def maxtoclevel = 4
        \toc
        ### Part of family 1: should not be nested `fd`
        ## Top-most ancestor of family 2
        #### should be empty nested
        ### part of family 2
        ## Top-most ancestor of family 3
        #### child1
        #### child2
        #### child3
        #### child4
        ## Top-most ancestor of family 4
        done.
        """ |> seval
    @test isapproxstr(h, raw"""
          <div class="franklin-toc">
          <ol>
            <li>
              <a href="#part_of_family_1_should_not_be_nested_fd">Part of family 1: should not be nested <code>fd</code></a>
            </li>
            <li>
              <a href="#top-most_ancestor_of_family_2">Top-most ancestor of family 2</a>
              <ol>
                <li style="list-style-type: none;">
                  <ol>
                    <li>
                      <a href="#should_be_empty_nested">should be empty nested</a>
                    </li>
                  </ol>
                </li>
                <li>
                  <a href="#part_of_family_2">part of family 2</a>
                </li>
              </ol>
            </li>
            <li>
              <a href="#top-most_ancestor_of_family_3">Top-most ancestor of family 3</a>
              <ol>
                <li>
                  <a href="#child1">child1</a>
                </li>
                <li>
                  <a href="#child2">child2</a>
                </li>
                <li>
                  <a href="#child3">child3</a>
                </li>
                <li>
                  <a href="#child4">child4</a>
                </li>
              </ol>
            </li>
            <li>
              <a href="#top-most_ancestor_of_family_4">Top-most ancestor of family 4</a>
            </li>
          </ol>
        </div>
        <h3 id="part_of_family_1_should_not_be_nested_fd"><a href="#part_of_family_1_should_not_be_nested_fd" class="header-anchor">Part of family 1: should not be nested <code>fd</code></a></h3>
        <h2 id="top-most_ancestor_of_family_2"><a href="#top-most_ancestor_of_family_2" class="header-anchor">Top-most ancestor of family 2</a></h2>
        <h4 id="should_be_empty_nested"><a href="#should_be_empty_nested" class="header-anchor">should be empty nested</a></h4>
        <h3 id="part_of_family_2"><a href="#part_of_family_2" class="header-anchor">part of family 2</a></h3>
        <h2 id="top-most_ancestor_of_family_3"><a href="#top-most_ancestor_of_family_3" class="header-anchor">Top-most ancestor of family 3</a></h2>
        <h4 id="child1"><a href="#child1" class="header-anchor">child1</a></h4>
        <h4 id="child2"><a href="#child2" class="header-anchor">child2</a></h4>
        <h4 id="child3"><a href="#child3" class="header-anchor">child3</a></h4>
        <h4 id="child4"><a href="#child4" class="header-anchor">child4</a></h4>
        <h2 id="top-most_ancestor_of_family_4"><a href="#top-most_ancestor_of_family_4" class="header-anchor">Top-most ancestor of family 4</a></h2>
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
