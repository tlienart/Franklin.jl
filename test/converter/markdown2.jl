# this follows `markdown.jl` but spurred by bugs/issues

function inter(st::String)
    tokens = J.find_tokens(st, J.MD_TOKENS, J.MD_1C_TOKENS)
    blocks, tokens = J.find_all_ocblocks(tokens, J.MD_OCB_ALL)
    lxdefs, tokens, braces, blocks = J.find_md_lxdefs(tokens, blocks)
    lxcoms, _ = J.find_md_lxcoms(tokens, lxdefs, braces)
    blocks2insert = J.merge_blocks(lxcoms, blocks)
    inter_md, mblocks = J.form_inter_md(st, blocks2insert, lxdefs)
    inter_html = J.md2html(inter_md)
    return inter_md, inter_html
end

@testset "Code+italic (#163)" begin
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
