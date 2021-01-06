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
    Base.precompile(Tuple{Core.kwftype(typeof(fd2html)),NamedTuple{(:dir,), Tuple{String}},typeof(fd2html),String})   # time: 0.61810833
    Base.precompile(Tuple{Core.kwftype(typeof(serve)),NamedTuple{(:single,), Tuple{Bool}},typeof(serve)})   # time: 0.37084788
    Base.precompile(Tuple{typeof(lx_show),LxCom,Vector{LxDef}})   # time: 0.32274863
    Base.precompile(Tuple{typeof(fd2html),String})   # time: 0.23594038
    Base.precompile(Tuple{Core.kwftype(typeof(convert_md)),NamedTuple{(:isinternal,), Tuple{Bool}},typeof(convert_md),String})   # time: 0.22428645
    Base.precompile(Tuple{Core.kwftype(typeof(serve)),NamedTuple{(:clear, :single, :cleanup, :nomess), NTuple{4, Bool}},typeof(serve)})   # time: 0.14878392
    let fbody = try __lookup_kwbody__(which(optimize, ())) catch missing end
        if !ismissing(fbody)
            precompile(fbody, (Bool,Bool,Bool,String,Bool,Function,Bool,Bool,Bool,typeof(optimize),))
        end
    end   # time: 0.07003818
    Base.precompile(Tuple{Core.kwftype(typeof(optimize)),NamedTuple{(:prerender,), Tuple{Bool}},typeof(optimize)})   # time: 0.05545673
    Base.precompile(Tuple{typeof(find_tokens),String,LittleDict{Char, Vector{Pair{Tuple{Int64, Bool, Function, Union{Nothing, Bool, Function}}, Symbol}}, Vector{Char}, Vector{Vector{Pair{Tuple{Int64, Bool, Function, Union{Nothing, Bool, Function}}, Symbol}}}},LittleDict{Char, Symbol, Vector{Char}, Vector{Symbol}}})   # time: 0.040931374
    Base.precompile(Tuple{typeof(hfun_taglist)})   # time: 0.030687159
    Base.precompile(Tuple{typeof(add_rss_item)})   # time: 0.029599395
    Base.precompile(Tuple{typeof(hfun_toc),Vector{String}})   # time: 0.02444929
    Base.precompile(Tuple{typeof(resolve_code_block),SubString{String}})   # time: 0.01858709
    Base.precompile(Tuple{typeof(hfun_redirect),Vector{String}})   # time: 0.015353491
    Base.precompile(Tuple{typeof(lx_textoutput),LxCom,Vector{LxDef}})   # time: 0.013971993
    Base.precompile(Tuple{typeof(reprocess),String,Vector{LxDef{SubString{String}}}})   # time: 0.012774653
    Base.precompile(Tuple{typeof(lx_textinput),LxCom,Vector{LxDef}})   # time: 0.01045118
    Base.precompile(Tuple{typeof(convert_block),OCBlock,Vector{LxDef}})   # time: 0.009655179
    Base.precompile(Tuple{typeof(generate_tag_pages)})   # time: 0.009324851
    Base.precompile(Tuple{typeof(process_config)})   # time: 0.00678984
    isdefined(Franklin, Symbol("#180#186")) && Base.precompile(Tuple{getfield(Franklin, Symbol("#180#186")),SubString{String}})   # time: 0.006691009
    Base.precompile(Tuple{typeof(convert_block),Token,Vector{LxDef}})   # time: 0.006101899
    Base.precompile(Tuple{typeof(write_tag_page),String})   # time: 0.004991966
    Base.precompile(Tuple{typeof(lx_literate),LxCom,Vector{LxDef}})   # time: 0.004831332
    Base.precompile(Tuple{typeof(html_code),SubString{String},SubString{String}})   # time: 0.004530656
    Base.precompile(Tuple{typeof(hfun_insert),Vector{String}})   # time: 0.003900784
    Base.precompile(Tuple{Type{LxDef},String,Int64,Pair{String, String}})   # time: 0.003559113
    Base.precompile(Tuple{Core.kwftype(typeof(convert_md)),NamedTuple{(:isrecursive,), Tuple{Bool}},typeof(convert_md),String})   # time: 0.003385631
    Base.precompile(Tuple{typeof(hfun_paginate),Vector{String}})   # time: 0.003321519
    Base.precompile(Tuple{Core.kwftype(typeof(serve)),NamedTuple{(:clear, :single, :nomess), Tuple{Bool, Bool, Bool}},typeof(serve)})   # time: 0.002933776
    Base.precompile(Tuple{typeof(locvar),Symbol})   # time: 0.002928755
    isdefined(Franklin, Symbol("#λ#23")) && Base.precompile(Tuple{getfield(Franklin, Symbol("#λ#23")),Int64,Char})   # time: 0.002772743
    Base.precompile(Tuple{Core.kwftype(typeof(fd2html)),NamedTuple{(:dir, :internal), Tuple{String, Bool}},typeof(fd2html),String})   # time: 0.002679923
    Base.precompile(Tuple{Type{LxDef},String,Int64,SubString{String}})   # time: 0.002655788
    Base.precompile(Tuple{Core.kwftype(typeof(fd2html)),NamedTuple{(:nop,), Tuple{Bool}},typeof(fd2html),String})   # time: 0.002494217
    Base.precompile(Tuple{Core.kwftype(typeof(optimize)),NamedTuple{(:minify, :prerender, :prepath), Tuple{Bool, Bool, String}},typeof(optimize)})   # time: 0.002491155
    isdefined(Franklin, Symbol("#λ#22")) && Base.precompile(Tuple{getfield(Franklin, Symbol("#λ#22")),SubString{String},Bool})   # time: 0.002363617
    Base.precompile(Tuple{Core.kwftype(typeof(serve)),NamedTuple{(:single, :clear, :cleanup), Tuple{Bool, Bool, Bool}},typeof(serve)})   # time: 0.002335907
    let fbody = try __lookup_kwbody__(which(convert_md, (SubString{String},Vector{LxDef},))) catch missing end
        if !ismissing(fbody)
            precompile(fbody, (Base.Iterators.Pairs{Symbol, Bool, Tuple{Symbol, Symbol}, NamedTuple{(:isrecursive, :has_mddefs), Tuple{Bool, Bool}}},typeof(convert_md),SubString{String},Vector{LxDef},))
        end
    end   # time: 0.002099546
    Base.precompile(Tuple{typeof(convert_block),LxEnv,Vector{LxDef}})   # time: 0.002070447
    Base.precompile(Tuple{typeof(convert_md),String})   # time: 0.002023048
    Base.precompile(Tuple{Type{HFun},SubString{String},SubString{String},Vector{SubString{String}}})   # time: 0.001731392
    Base.precompile(Tuple{typeof(hfun_href),Vector{String}})   # time: 0.001713784
    Base.precompile(Tuple{Core.kwftype(typeof(fd2html)),NamedTuple{(:internal,), Tuple{Bool}},typeof(fd2html),String})   # time: 0.001555199
    isdefined(Franklin, Symbol("#λ#22")) && Base.precompile(Tuple{getfield(Franklin, Symbol("#λ#22")),String,Bool})   # time: 0.001472338
    Base.precompile(Tuple{Core.kwftype(typeof(convert_md)),NamedTuple{(:isrecursive, :has_mddefs, :nostripp), Tuple{Bool, Bool, Bool}},typeof(convert_md),SubString{String},Vector{LxDef}})   # time: 0.001085887
end
