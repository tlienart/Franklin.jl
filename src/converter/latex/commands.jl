"""Convenience function to create pairs (commandname => simple lxdef)"""
lxd(n::String, k::Int, d::String="") = "\\" * n => LxDef("\\" * n, k, subs(d))

const LX_INTERNAL_COMMANDS = [
    # ---------------
    # Hyperreferences (see converter/latex/hyperrefs.jl)
    lxd("eqref",    1), # \eqref{id}
    lxd("cite",     1), # \cite{id}
    lxd("citet",    1), # \citet{id}
    lxd("citep",    1), # \citet{id}
    lxd("label",    1), # \label{id}
    lxd("biblabel", 2), # \biblabel{id}{name}
    lxd("toc",      0), # \toc
    # -------------------
    # inclusion / outputs (see converter/latex/io.jl)
    lxd("input",      2), # \input{what}{rpath}
    lxd("output",     1), # \output{rpath}
    lxd("show",       1), # \show{rpath}
    lxd("textoutput", 1), # \textoutput{rpath}
    lxd("textinput",  1), # \textinput{rpath}
    lxd("figalt",     2), # \figalt{alt}{rpath}
    lxd("tableinput", 2), # \tableinput{header}{rpath}
    lxd("literate",   1), # \literate{rpath}
    # ------------------
    # DERIVED / EXPLICIT
    lxd("fig",             1, "\\figalt{}{#1}"),
    lxd("style",           2, "~~~<span style=\"!#1\">~~~!#2~~~</span>~~~"),
    lxd("tableofcontents", 0, "\\toc"),
    lxd("codeoutput",      1, "\\output{#1}"), # \codeoutput{rpath}
    ]

"""
List of latex definitions accessible to all pages. This is filled when the
config file is read (via `manager/file_utils.jl:process_config`).
"""
const GLOBAL_LXDEFS = LittleDict{String,LxDef}()

"""
Convenience function to allocate default values for global latex commands
accessible throughout the site. See [`resolve_lxcom`](@ref).
"""
 function def_GLOBAL_LXDEFS!()::Nothing
    empty!(GLOBAL_LXDEFS)
    for (name, def) in LX_INTERNAL_COMMANDS
        GLOBAL_LXDEFS[name] = def
    end
    nothing
end
