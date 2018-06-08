using JuDoc
@static if VERSION < v"0.7.0-DEV.2005"
    using Base.Test
else
    using Test
end

# --- TEST ---
include("t_find_replace_md.jl")
include("t_find_replace_html.jl")
include("t_jd_vars.jl")
include("t_jd_paths.jl") # run with care, once run, cannot be re-run
include("t_process_files.jl")
