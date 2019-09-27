import DataStructures: OrderedDict

# This set of tests directly uses the high-level `convert` functions
# And checks the behaviour is as expected.

J.def_GLOBAL_LXDEFS!()
cmd   = st -> J.convert_md(st, collect(values(J.GLOBAL_LXDEFS)))
chtml = t -> J.convert_html(t...)
conv  = st -> st |> cmd |> chtml

# convenience function that squeezes out all whitespaces and line returns out of a string
# and checks if the resulting strings are equal. When expecting a specific string +- some
# spaces, this is very convenient. Use == if want to check exact strings.
isapproxstr(s1::String, s2::String) =
    isequal(map(s->replace(s, r"\s|\n"=>""), (s1, s2))...)

# this is a slightly ridiculous requirement but apparently the `eval` blocks
# don't play well with Travis nor windows while testing, so you just need to forcibly
# specify that LinearAlgebra and Random are used (even though the included block says
# the same thing).
if get(ENV, "CI", "false") == "true" || Sys.iswindows()
    import Pkg; Pkg.add("LinearAlgebra"); Pkg.add("Random");
    using LinearAlgebra, Random;
end

# takes md input and outputs the html (good for integration testing)
function seval(st)
    J.def_GLOBAL_PAGE_VARS!()
    J.def_GLOBAL_LXDEFS!()
    m, v = J.convert_md(st, collect(values(J.GLOBAL_LXDEFS)))
    h = J.convert_html(m, v)
    return h
end


function explore_md_steps(mds)
    J.def_GLOBAL_PAGE_VARS!()
    J.def_GLOBAL_LXDEFS!()
    J.def_LOCAL_PAGE_VARS!()
    J.def_PAGE_EQREFS!()
    J.def_PAGE_BIBREFS!()
    J.def_PAGE_FNREFS!()

    steps = OrderedDict{Symbol,NamedTuple}()

    # tokenize
    tokens = J.find_tokens(mds, J.MD_TOKENS, J.MD_1C_TOKENS)
    tokens = J.find_indented_blocks(tokens, mds)
    steps[:tokenization] = (tokens=tokens,)

    fn_refs = J.validate_footnotes!(tokens)
    steps[:fn_validation] = (tokens=tokens, fn_refs=fn_refs)

    # ocblocks
    blocks, tokens = J.find_all_ocblocks(tokens, J.MD_OCB_ALL)
    steps[:ocblocks] = (blocks=blocks, tokens=tokens)

    # filter
    filter!(τ -> τ.name != :LINE_RETURN, tokens)
    filter!(β -> J.validate_header_block(β), blocks)
    steps[:filter] = (tokens=tokens, blocks=blocks)

    # latex commands
    lxdefs, tokens, braces, blocks = J.find_md_lxdefs(tokens, blocks)
    lxcoms, _ = J.find_md_lxcoms(tokens, lxdefs, braces)
    steps[:latex] = (lxdefs=lxdefs, tokens=tokens, braces=braces,
                     blocks=blocks, lxcoms=lxcoms)

    sp_chars = J.find_special_chars(tokens)
    steps[:spchars] = (spchars=sp_chars,)

    blocks2insert = J.merge_blocks(lxcoms, J.deactivate_divs(blocks), sp_chars)
    steps[:blocks2insert] = (blocks2insert=blocks2insert,)

    inter_md, mblocks = J.form_inter_md(mds, blocks2insert, lxdefs)
    steps[:inter_md] = (inter_md=inter_md, mblocks=mblocks)

    inter_html = J.md2html(inter_md; stripp=false)
    steps[:inter_html] = (inter_html=inter_html,)

    lxcontext = J.LxContext(lxcoms, lxdefs, braces)
    hstring   = J.convert_inter_html(inter_html, mblocks, lxcontext)
    steps[:hstring] = (hstring=hstring,)

    return steps
end

function explore_h_steps(hs)
    steps = OrderedDict{Symbol,NamedTuple}()

    tokens = J.find_tokens(hs, J.HTML_TOKENS, J.HTML_1C_TOKENS)
    steps[:tokenization] = (tokens=tokens,)

    hblocks, tokens = J.find_all_ocblocks(tokens, J.HTML_OCB)
    filter!(hb -> hb.name != :COMMENT, hblocks)
    steps[:ocblocks] = (hblocks=hblocks, tokens=tokens)

    qblocks = J.qualify_html_hblocks(hblocks)
    steps[:qblocks] = (qblocks=qblocks,)

    cblocks, qblocks = J.find_html_cblocks(qblocks)
    cdblocks, qblocks = J.find_html_cdblocks(qblocks)
    cpblocks, qblocks = J.find_html_cpblocks(qblocks)
    steps[:cblocks] = (cblocks=cblocks, cdblocks=cdblocks, cpblocks=cpblocks,
                         qblocks=qblocks)

    hblocks = J.merge_blocks(qblocks, cblocks, cdblocks, cpblocks)
    steps[:hblocks] = (hblocks=hblocks,)

    return steps
end
