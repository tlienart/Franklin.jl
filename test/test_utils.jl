import DataStructures: OrderedDict

# This set of tests directly uses the high-level `convert` functions
# And checks the behaviour is as expected.

F.def_GLOBAL_LXDEFS!()
cmd   = st -> F.convert_md(st)
chtml = t -> F.convert_html(t)
conv  = st -> st |> cmd |> chtml

set_curpath(path) =
    (F.set_var!(F.LOCAL_VARS, "fd_rpath", path); F.locvar("fd_rpath"))

# convenience function that squeezes out all whitespaces and line returns out of a string
# and checks if the resulting strings are equal. When expecting a specific string +- some
# spaces, this is very convenient. Use == if want to check exact strings.
isapproxstr(s1::AbstractString, s2::AbstractString) =
    isequal(map(s->replace(s, r"\s|\n"=>""), String.((s1, s2)))...)

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
    F.def_GLOBAL_VARS!()
    F.def_GLOBAL_LXDEFS!()
    m = F.convert_md(st)
    h = F.convert_html(m)
    return h
end

function set_globals()
    F.def_GLOBAL_VARS!()
    F.def_GLOBAL_LXDEFS!()
    empty!(F.LOCAL_VARS)
    F.def_LOCAL_VARS!()
    set_curpath("index.md")
    # F.FD_ENV[:CUR_PATH_WITH_EVAL] = ""
end

function explore_md_steps(mds)
    F.def_GLOBAL_VARS!()
    F.def_GLOBAL_LXDEFS!()
    empty!(F.RSS_DICT)

    F.def_LOCAL_VARS!()
    F.def_PAGE_HEADERS!()
    F.def_PAGE_EQREFS!()
    F.def_PAGE_BIBREFS!()
    F.def_PAGE_FNREFS!()
    F.def_PAGE_LINK_DEFS!()

    steps = OrderedDict{Symbol,NamedTuple}()

    # tokenize
    tokens = F.find_tokens(mds, F.MD_TOKENS, F.MD_1C_TOKENS)
    F.validate_footnotes!(tokens)
    F.validate_headers!(tokens)
    hrules = F.find_hrules!(tokens)
    F.find_indented_blocks!(tokens, mds)
    steps[:tokenization] =  (tokens=tokens,)

    # ocblocks
    blocks, tokens = F.find_all_ocblocks(tokens, F.MD_OCB)
    toks_pre_ocb   = deepcopy(tokens)

    blocks2, tokens = F.find_all_ocblocks(tokens, vcat(F.MD_OCB2, F.MD_OCB_MATH))
    append!(blocks, blocks2)
    F.deactivate_inner_blocks!(blocks)

    F.merge_indented_blocks!(blocks, mds)
    F.filter_indented_blocks!(blocks)
    steps[:ocblocks] = (blocks=blocks, tokens=tokens)

    # filter
    filter!(τ -> τ.name ∉ F.L_RETURNS, tokens)
    steps[:filter] = (tokens=tokens, blocks=blocks)

    F.validate_and_store_link_defs!(blocks)

    # latex commands
    lxdefs, tokens, braces, blocks = F.find_lxdefs(tokens, blocks)

    # lxdefs = cat(F.pastdef.(collect(values(F.GLOBAL_LXDEFS))), lxdefs, dims=1)

    lxcoms, _ = F.find_lxcoms(tokens, lxdefs, braces)
    steps[:latex] = (lxdefs=lxdefs, tokens=tokens, braces=braces,
                     blocks=blocks, lxcoms=lxcoms)

    dbb = F.find_double_brace_blocks(toks_pre_ocb)

    sp_chars = F.find_special_chars(tokens)
    steps[:spchars] = (spchars=sp_chars,)

    fnrefs = filter(τ -> τ.name == :FOOTNOTE_REF, tokens)
    steps[:fnrefs] = (fnrefs=fnrefs,)

    b2insert = F.merge_blocks(lxcoms, F.deactivate_divs(blocks),
                              sp_chars, fnrefs, dbb, hrules)
    steps[:b2insert] = (b2insert=b2insert,)

    inter_md, mblocks = F.form_inter_md(mds, b2insert, lxdefs)
    steps[:inter_md] = (inter_md=inter_md, mblocks=mblocks)

    inter_html = F.md2html(inter_md; stripp=false)
    steps[:inter_html] = (inter_html=inter_html,)

    hstring   = F.convert_inter_html(inter_html, mblocks, lxdefs)
    steps[:hstring] = (hstring=hstring,)

    return steps
end

function explore_h_steps(hs, allvars=F.PageVars())
    steps = OrderedDict{Symbol,NamedTuple}()

    tokens = F.find_tokens(hs, F.HTML_TOKENS, F.HTML_1C_TOKENS)
    steps[:tokenization] = (tokens=tokens,)

    hblocks, tokens = F.find_all_ocblocks(tokens, F.HTML_OCB)
    filter!(hb -> hb.name != :COMMENT, hblocks)
    steps[:ocblocks] = (hblocks=hblocks, tokens=tokens)

    qblocks = F.qualify_html_hblocks(hblocks)
    steps[:qblocks] = (qblocks=qblocks,)

    fhs = F.process_html_qblocks(hs, allvars, qblocks)
    steps[:fhs] = (fhs=fhs,)

    return steps
end

gotd() = (flush_td(); cd(td); F.FOLDER_PATH[] = td)

function fs1()
    F.FD_ENV[:STRUCTURE] = v"0.1"
    gotd()
    empty!(F.PATHS)
    F.set_paths!()
    mkdir(F.PATHS[:src])
    mkdir(F.PATHS[:src_pages])
    mkdir(F.PATHS[:libs])
    mkdir(F.PATHS[:src_css])
    mkdir(F.PATHS[:src_html])
    mkdir(F.PATHS[:assets])
end

function fs2()
    F.FD_ENV[:STRUCTURE] = v"0.2"
    gotd()
    empty!(F.PATHS)
    F.set_paths!()
    mkdir(F.PATHS[:site])
    mkdir(F.PATHS[:assets])
    mkdir(F.PATHS[:css])
    mkdir(F.PATHS[:layout])
    mkdir(F.PATHS[:libs])
    mkdir(F.PATHS[:literate])
end
