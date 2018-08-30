"""
    resolve_lxcom(lxc, s, lxdefs, inmath)

Take a `LxCom` object `lxc` appearing in string `s` and try to resolve it using
the `lxdefs`. Provided one exists etc, the definition is plugged in then sent
forward to be re-parsed (in case further latex is present).
"""
function resolve_lxcom(lxc::LxCom, s::AbstractString, lxdefs::Vector{LxDef},
                       inmath::Bool=false)

    lxdef = getdef(lxc)
    # lxdef = nothing means we're inmath & not found, let KaTeX deal with it
    isnothing(lxdef) && return lxname
    # lxdef = something -> maybe inmath + found; retrieve & apply
    partial = lxdef
    for (argnum, b) ∈ enumerate(lxc.braces)
        partial = replace(partial, "#$argnum" => subs(s, b.from+1, b.to-1))
    end
    partial = ifelse(inmath, mathenv(partial), partial) * EOS
    # reprocess (we don't care about jd_vars=nothing)
    plug, _ = convert_md(partial, lxdefs, isrecursive=true, isconfig=false,
                         has_mddefs=false)

    return plug
end
