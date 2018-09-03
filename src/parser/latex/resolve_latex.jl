"""
    resolve_lxcom(lxc, lxdefs, inmath)

Take a `LxCom` object `lxc` and try to resolve it. Provided a definition
exists etc, the definition is plugged in then sent forward to be re-parsed
(in case further latex is present).
"""
function resolve_lxcom(lxc::LxCom, lxdefs::Vector{LxDef}, inmath::Bool=false)

    # retrieve the definition attached to the command
    lxdef = getdef(lxc)
    # lxdef = nothing means we're inmath & not found -> let KaTeX deal with it
    isnothing(lxdef) && return lxname
    # lxdef = something -> maybe inmath + found; retrieve & apply
    partial = lxdef
    for (argnum, β) ∈ enumerate(lxc.braces)
        partial = replace(partial, "#$argnum" => braces_content(β))
    end
    partial = ifelse(inmath, mathenv(partial), partial) * EOS
    # reprocess (we don't care about jd_vars=nothing)
    plug, _ = convert_md(partial, lxdefs, isrecursive=true, isconfig=false,
                         has_mddefs=false)
    return plug
end
