st = raw"""
    A\newcommand{\eqa}[1]{\begin{eqnarray}#1\end{eqnarray}}B
    C\eqa{\sin^2(x)+\cos^2(x) &=& 1}D
    """ * J.EOS

J.def_JD_LOC_EQDICT()
J.def_GLOB_VARS()

tokens = J.find_tokens(st, J.MD_TOKENS, J.MD_1C_TOKENS)
blocks, tokens = J.find_all_ocblocks(tokens, J.MD_OCB_ALL)
lxdefs, tokens, braces, blocks = J.find_lxdefs(tokens, blocks)
lxcoms, _ = J.find_md_lxcoms(tokens, lxdefs, braces)

blocks2insert = J.merge_blocks(lxcoms, blocks)

inter_md, mblocks = J.form_inter_md(st, blocks2insert, lxdefs)

@test inter_md == "AB\nC ##JDINSERT## D\n"
@test length(mblocks) == 1
@test mblocks[1].ss == "\\eqa{\\sin^2(x)+\\cos^2(x) &=& 1}"

inter_html = J.md2html(inter_md)

J.JD_GLOB_VARS["prerender"] = Pair(true, (Bool,))

lxcontext = J.LxContext(lxcoms, lxdefs, braces)
hstring   = J.convert_inter_html(inter_html, mblocks, lxcontext)
