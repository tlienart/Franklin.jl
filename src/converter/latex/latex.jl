"""
$(SIGNATURES)

Take a `LxCom` object `lxc` and try to resolve it. Provided a definition exists
etc, the definition is plugged in then sent forward to be re-parsed (in case
further latex is present).
"""
function resolve_lxcom(lxc::LxCom, lxdefs::Vector{LxDef};
                       inmath::Bool=false)::String
    # retrieve the definition the command points to
    lxd = getdef(lxc)
    # it will be `nothing` in math mode, let KaTeX have it
    lxd === nothing && return lxc.ss
    # otherwise it may be
    # -> empty, in which case try to find a specific internal definition or
    # return an empty string (see `commands.jl`)
    # -> non-empty, in which case just apply that.
    if isempty(lxd)
        # see if a function `lx_name` exists
        name = getname(lxc) # `\\cite` -> `cite`
        fun  = Symbol("lx_" * name)
        if isdefined(Franklin, fun)
            # apply that function
            return eval(:($fun($lxc, $lxdefs)))
        else
            return ""
        end
    end
    # non-empty case, take the definition and iteratively replace any `#...`
    partial = lxd
    for (i, brace) in enumerate(lxc.braces)
        cont    = strip(content(brace))
        # space-sensitive 'unsafe' one
        partial = replace(partial, "!#$i" => cont)
        # space-insensitive 'safe' one (e.g. `\mathbb#1`)
        partial = replace(partial, "#$i" => " " * cont)
    end
    # if 'inmath' surround accordingly so that this information is preserved
    partial = ifelse(inmath, mathenv(partial), partial)
    # reprocess
    return reprocess(partial, lxdefs)
end

"""Convenience function to take a string and re-parse it."""
function reprocess(s::AS, lxdefs::Vector{LxDef})
    r = convert_md(s, lxdefs;
                   isrecursive=true, isconfig=false, has_mddefs=false)
    return r
end
