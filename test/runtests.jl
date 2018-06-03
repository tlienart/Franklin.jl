using JuDoc
@static if VERSION < v"0.7.0-DEV.2005"
    using Base.Test
else
    using Test
end

# --- TEST ---
include("t_find_replace_md.jl")
include("t_find_replace_html.jl")
include("t_process_files.jl")
