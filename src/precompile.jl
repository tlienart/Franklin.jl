const __bodyfunction__ = Dict{Method,Any}()

# Find keyword "body functions" (the function that contains the body
# as written by the developer, called after all missing keyword-arguments
# have been assigned values), in a manner that doesn't depend on
# gensymmed names.
# `mnokw` is the method that gets called when you invoke it without
# supplying any keywords.
function __lookup_kwbody__(mnokw::Method)
    function getsym(arg)
        isa(arg, Symbol) && return arg
        @assert isa(arg, GlobalRef)
        return arg.name
    end

    f = get(__bodyfunction__, mnokw, nothing)
    if f === nothing
        fmod = mnokw.module
        # The lowered code for `mnokw` should look like
        #   %1 = mkw(kwvalues..., #self#, args...)
        #        return %1
        # where `mkw` is the name of the "active" keyword body-function.
        ast = Base.uncompressed_ast(mnokw)
        if isa(ast, Core.CodeInfo) && length(ast.code) >= 2
            callexpr = ast.code[end-1]
            if isa(callexpr, Expr) && callexpr.head == :call
                fsym = callexpr.args[1]
                if isa(fsym, Symbol)
                    f = getfield(fmod, fsym)
                elseif isa(fsym, GlobalRef)
                    if fsym.mod === Core && fsym.name === :_apply
                        f = getfield(mnokw.module, getsym(callexpr.args[2]))
                    elseif fsym.mod === Core && fsym.name === :_apply_iterate
                        f = getfield(mnokw.module, getsym(callexpr.args[3]))
                    else
                        f = getfield(fsym.mod, fsym.name)
                    end
                else
                    f = missing
                end
            else
                f = missing
            end
        else
            f = missing
        end
        __bodyfunction__[mnokw] = f
    end
    return f
end

function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    Base.precompile(Tuple{typeof(convert_md),String})   # time: 2.344381
    Base.precompile(Tuple{Core.kwftype(typeof(serve)),NamedTuple{(:single,), Tuple{Bool}},typeof(serve)})   # time: 0.8439658
    Base.precompile(Tuple{typeof(lx_show),LxCom,Vector{LxDef}})   # time: 0.42509058
    Base.precompile(Tuple{Core.kwftype(typeof(fd2html)),NamedTuple{(:dir,), Tuple{String}},typeof(fd2html),String})   # time: 0.40266374
    Base.precompile(Tuple{typeof(literate_to_franklin),String})   # time: 0.37523866
    let fbody = try __lookup_kwbody__(which(convert_md, (String,Vector{LxDef},))) catch missing end
        if !ismissing(fbody)
            precompile(fbody, (Bool,Bool,Bool,Bool,Bool,Bool,typeof(convert_md),String,Vector{LxDef},))
        end
    end   # time: 0.3324818
    Base.precompile(Tuple{typeof(fd2html),String})   # time: 0.2849749
    Base.precompile(Tuple{typeof(verify_links)})   # time: 0.23714699
    Base.precompile(Tuple{Core.kwftype(typeof(serve)),NamedTuple{(:clear, :single, :cleanup, :nomess), NTuple{4, Bool}},typeof(serve)})   # time: 0.18729618
    Base.precompile(Tuple{Core.kwftype(typeof(optimize)),NamedTuple{(:prerender,), Tuple{Bool}},typeof(optimize)})   # time: 0.07916649
    Base.precompile(Tuple{typeof(lx_input),LxCom,Vector{LxDef}})   # time: 0.07533654
    Base.precompile(Tuple{typeof(context),String,Int64})   # time: 0.069593124
    Base.precompile(Tuple{typeof(fd_date),DateTime})   # time: 0.06647657
    Base.precompile(Tuple{typeof(reprocess),String,Vector{LxDef{SubString{String}}}})   # time: 0.06567904
    let fbody = try __lookup_kwbody__(which(optimize, ())) catch missing end
        if !ismissing(fbody)
            precompile(fbody, (Bool,Bool,Bool,String,Bool,Function,Bool,Bool,Bool,typeof(optimize),))
        end
    end   # time: 0.058180097
    Base.precompile(Tuple{typeof(lx_tableinput),LxCom,Vector{LxDef}})   # time: 0.05248551
    Base.precompile(Tuple{typeof(form_output_path),String,String,Symbol})   # time: 0.048748575
    Base.precompile(Tuple{Core.kwftype(typeof(_scan_input_dir!)),NamedTuple{(:files2ignore, :dirs2ignore), Tuple{Vector{String}, Vector{String}}},typeof(_scan_input_dir!),Dict{Pair{String, String}, Float64},Dict{Pair{String, String}, Float64},Dict{Pair{String, String}, Float64},Dict{Pair{String, String}, Float64},Dict{Pair{String, String}, Float64}})   # time: 0.037173398
    Base.precompile(Tuple{typeof(literate_to_franklin),SubString{String}})   # time: 0.0368632
    Base.precompile(Tuple{typeof(lx_citet),LxCom,Vector{LxDef}})   # time: 0.031762727
    Base.precompile(Tuple{typeof(clear_dicts)})   # time: 0.03162326
    Base.precompile(Tuple{typeof(set_vars!),LittleDict{String, Pair, Vector{String}, Vector{Pair}},Vector{Pair{String, String}}})   # time: 0.031474527
    Base.precompile(Tuple{typeof(set_var!),LittleDict{String, Pair, Vector{String}, Vector{Pair}},String,Vector{String}})   # time: 0.02829018
    Base.precompile(Tuple{Core.kwftype(typeof(_lx_input_code)),NamedTuple{(:lang,), Tuple{String}},typeof(_lx_input_code),SubString{String}})   # time: 0.02467124
    Base.precompile(Tuple{typeof(add_rss_item)})   # time: 0.021984044
    Base.precompile(Tuple{typeof(resolve_code_block),SubString{String}})   # time: 0.02185676
    Base.precompile(Tuple{typeof(find_tokens),String,LittleDict{Char, Vector{Pair{Tuple{Int64, Bool, Function, Union{Nothing, Bool, Function}}, Symbol}}, Vector{Char}, Vector{Vector{Pair{Tuple{Int64, Bool, Function, Union{Nothing, Bool, Function}}, Symbol}}}},LittleDict{Char, Symbol, Vector{Char}, Vector{Symbol}}})   # time: 0.019084884
    Base.precompile(Tuple{typeof(_isempty),Regex})   # time: 0.01664262
    Base.precompile(Tuple{Core.kwftype(typeof(_scan_input_dir!)),NamedTuple{(:files2ignore, :dirs2ignore), Tuple{Vector{Any}, Vector{Any}}},typeof(_scan_input_dir!),Dict{Pair{String, String}, Float64},Dict{Pair{String, String}, Float64},Dict{Pair{String, String}, Float64},Dict{Pair{String, String}, Float64},Dict{Pair{String, String}, Float64}})   # time: 0.01659975
    Base.precompile(Tuple{typeof(lx_literate),LxCom,Vector{LxDef}})   # time: 0.016286423
    Base.precompile(Tuple{typeof(def_GLOBAL_LXDEFS!)})   # time: 0.012746706
    Base.precompile(Tuple{typeof(print_final),String,Float64})   # time: 0.012520476
    Base.precompile(Tuple{typeof(invert_dict),LittleDict{String, Vector{String}, Vector{String}, Vector{Vector{String}}}})   # time: 0.0111298
    Base.precompile(Tuple{typeof(lx_toc),LxCom,Vector{LxDef}})   # time: 0.010889063
    Base.precompile(Tuple{typeof(process_config)})   # time: 0.009949524
    Base.precompile(Tuple{typeof(resolve_rpath),String})   # time: 0.009940163
    Base.precompile(Tuple{typeof(set_paths!)})   # time: 0.008962243
    Base.precompile(Tuple{typeof(convert_block),OCBlock,Vector{LxDef}})   # time: 0.008342328
    Base.precompile(Tuple{typeof(convert_block),Token,Vector{LxDef}})   # time: 0.007395904
    Base.precompile(Tuple{typeof(merge_blocks),Vector{LxEnv},Vector{LxCom},Vector{OCBlock},Vector{HTML_SPCH},Vector{Token},Vector{OCBlock},Vector{Token}})   # time: 0.007163587
    Base.precompile(Tuple{typeof(set_var!),LittleDict{String, Pair, Vector{String}, Vector{Pair}},String,LittleDict{String, Vector{String}, Vector{String}, Vector{Vector{String}}}})   # time: 0.007084686
    Base.precompile(Tuple{typeof(match_url),String,SubString{String}})   # time: 0.006983826
    isdefined(Franklin, Symbol("#178#184")) && Base.precompile(Tuple{getfield(Franklin, Symbol("#178#184")),SubString{String}})   # time: 0.006874233
    Base.precompile(Tuple{typeof(generate_tag_pages)})   # time: 0.006868674
    Base.precompile(Tuple{typeof(lx_textoutput),LxCom,Vector{LxDef}})   # time: 0.006855863
    Base.precompile(Tuple{typeof(_lx_input_plot),SubString{String},String})   # time: 0.00678375
    Base.precompile(Tuple{typeof(match_url),String,String})   # time: 0.006312719
    Base.precompile(Tuple{typeof(def_GLOBAL_VARS!)})   # time: 0.006208385
    Base.precompile(Tuple{typeof(lx_figalt),LxCom,Vector{LxDef}})   # time: 0.006156132
    Base.precompile(Tuple{typeof(_lx_input_plot),SubString{String},SubString{String}})   # time: 0.005962823
    Base.precompile(Tuple{typeof(literate_post_process),String})   # time: 0.005867754
    Base.precompile(Tuple{typeof(csv2html),String,SubString{String}})   # time: 0.005569093
    Base.precompile(Tuple{typeof(write_tag_page),String})   # time: 0.005161386
    Base.precompile(Tuple{Core.kwftype(typeof(convert_md)),NamedTuple{(:isrecursive,), Tuple{Bool}},typeof(convert_md),String})   # time: 0.004899337
    Base.precompile(Tuple{typeof(is_footnote),Int64,Char})   # time: 0.004760328
    Base.precompile(Tuple{typeof(process_file),Symbol,Pair{String, String},String,Vararg{Any, N} where N})   # time: 0.004760095
    Base.precompile(Tuple{typeof(lx_textinput),LxCom,Vector{LxDef}})   # time: 0.004698063
    Base.precompile(Tuple{typeof(set_var!),LittleDict{String, Pair, Vector{String}, Vector{Pair}},String,Int64})   # time: 0.004546552
    Base.precompile(Tuple{typeof(literate_folder),String})   # time: 0.004467434
    Base.precompile(Tuple{typeof(get_url),String})   # time: 0.004099814
    Base.precompile(Tuple{typeof(lx_biblabel),LxCom,Vector{LxDef}})   # time: 0.004069273
    Base.precompile(Tuple{typeof(mddef_warn),String,String,Tuple{DataType}})   # time: 0.003842698
    Base.precompile(Tuple{typeof(run_code),Module,String,String})   # time: 0.003811778
    Base.precompile(Tuple{typeof(write_rss_xml),String,String,String,String,OrderedDict{String, RSSItem}})   # time: 0.003761276
    Base.precompile(Tuple{typeof(invert_dict),LittleDict{String, Set{String}, Vector{String}, Vector{Set{String}}}})   # time: 0.003711031
    Base.precompile(Tuple{typeof(check_type),DataType,Tuple{DataType, DataType, DataType}})   # time: 0.003657296
    Base.precompile(Tuple{typeof(check_type),DataType,Tuple{DataType, DataType}})   # time: 0.003462811
    Base.precompile(Tuple{typeof(pastdef),LxDef{Pair{SubString{String}, SubString{String}}}})   # time: 0.00330769
    Base.precompile(Tuple{Core.kwftype(typeof(fd2html)),NamedTuple{(:dir, :internal), Tuple{String, Bool}},typeof(fd2html),String})   # time: 0.003237703
    Base.precompile(Tuple{Type{LxDef},String,Int64,SubString{String}})   # time: 0.003226063
    Base.precompile(Tuple{Core.kwftype(typeof(serve)),NamedTuple{(:clear, :single, :nomess), Tuple{Bool, Bool, Bool}},typeof(serve)})   # time: 0.003150757
    Base.precompile(Tuple{typeof(is_emoji),Int64,Char})   # time: 0.003124704
    Base.precompile(Tuple{Core.kwftype(typeof(fd2html)),NamedTuple{(:nop,), Tuple{Bool}},typeof(fd2html),String})   # time: 0.003029122
    isdefined(Franklin, Symbol("#λ#23")) && Base.precompile(Tuple{getfield(Franklin, Symbol("#λ#23")),Int64,Char})   # time: 0.00295206
    Base.precompile(Tuple{typeof(locvar),Symbol})   # time: 0.002873653
    Base.precompile(Tuple{Type{LxDef},String,Int64,Pair{String, String}})   # time: 0.002818789
    Base.precompile(Tuple{Core.kwftype(typeof(optimize)),NamedTuple{(:minify, :prerender, :prepath), Tuple{Bool, Bool, String}},typeof(optimize)})   # time: 0.002796317
    Base.precompile(Tuple{typeof(lx_citep),LxCom,Vector{LxDef}})   # time: 0.002792075
    Base.precompile(Tuple{typeof(check_type),DataType,Tuple{DataType}})   # time: 0.002576553
    Base.precompile(Tuple{typeof(resolve_args),SubString{String},Vector{OCBlock}})   # time: 0.002519657
    Base.precompile(Tuple{Core.kwftype(typeof(serve)),NamedTuple{(:single, :clear, :cleanup), Tuple{Bool, Bool, Bool}},typeof(serve)})   # time: 0.002484669
    Base.precompile(Tuple{typeof(convert_block),LxEnv,Vector{LxDef}})   # time: 0.002432935
    Base.precompile(Tuple{typeof(resolve_args),String,Vector{OCBlock}})   # time: 0.002267043
    Base.precompile(Tuple{typeof(validate_start_of_line!),Vector{Token},NTuple{6, Symbol}})   # time: 0.002158351
    Base.precompile(Tuple{typeof(lx_cite),LxCom,Vector{LxDef}})   # time: 0.002095412
    Base.precompile(Tuple{Core.kwftype(typeof(fd2html)),NamedTuple{(:internal,), Tuple{Bool}},typeof(fd2html),String})   # time: 0.002086543
    let fbody = try __lookup_kwbody__(which(scan_input_dir!, (Dict{Pair{String, String}, Float64},Vararg{Dict{Pair{String, String}, Float64}, N} where N,))) catch missing end
        if !ismissing(fbody)
            precompile(fbody, (Base.Iterators.Pairs{Union{}, Union{}, Tuple{}, NamedTuple{(), Tuple{}}},typeof(scan_input_dir!),Dict{Pair{String, String}, Float64},Vararg{Dict{Pair{String, String}, Float64}, N} where N,))
        end
    end   # time: 0.001690126
    Base.precompile(Tuple{typeof(lx_eqref),LxCom,Vector{LxDef}})   # time: 0.001631687
    Base.precompile(Tuple{typeof(parse_code),String})   # time: 0.001560939
    Base.precompile(Tuple{typeof(scan_input_dir!),Dict{Pair{String, String}, Float64},Vararg{Any, N} where N})   # time: 0.001543908
    isdefined(Franklin, Symbol("#λ#22")) && Base.precompile(Tuple{getfield(Franklin, Symbol("#λ#22")),SubString{String},Bool})   # time: 0.001345152
    Base.precompile(Tuple{Core.kwftype(typeof(convert_md)),NamedTuple{(:isrecursive, :has_mddefs, :nostripp), Tuple{Bool, Bool, Bool}},typeof(convert_md),SubString{String},Vector{LxDef}})   # time: 0.001344118
    Base.precompile(Tuple{Core.kwftype(typeof(parse_rpath)),NamedTuple{(:code,), Tuple{Bool}},typeof(parse_rpath),String})   # time: 0.001315047
    Base.precompile(Tuple{Core.kwftype(typeof(convert_md)),NamedTuple{(:isrecursive, :isconfig, :has_mddefs, :nostripp), NTuple{4, Bool}},typeof(convert_md),String,Vector{LxDef}})   # time: 0.001285796
    isdefined(Franklin, Symbol("#λ#22")) && Base.precompile(Tuple{getfield(Franklin, Symbol("#λ#22")),String,Bool})   # time: 0.001266986
    Base.precompile(Tuple{Core.kwftype(typeof(html_content)),NamedTuple{(:class, :id), Tuple{String, String}},typeof(html_content),String,String})   # time: 0.00117603
    Base.precompile(Tuple{typeof(convert_block),HTML_SPCH,Vector{LxDef}})   # time: 0.001095471
    isdefined(Franklin, Symbol("#λ#22")) && Base.precompile(Tuple{getfield(Franklin, Symbol("#λ#22")),SubString{String},Bool})   # time: 0.001089079
    Base.precompile(Tuple{Core.kwftype(typeof(parse_rpath)),NamedTuple{(:canonical,), Tuple{Bool}},typeof(parse_rpath),SubString{String}})   # time: 0.00102106
end
