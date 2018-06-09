using JuDoc
@static if VERSION < v"0.7.0-DEV.2005"
    using Base.Test
else
    using Test
end

include("t_jd_paths.jl") # MUST BE RUN FIRST AND ONLY ONCE

# --- CORE TESTS ---

include("t_find_replace_md.jl")
include("t_find_replace_html.jl")
include("t_jd_vars.jl")
include("t_process_files.jl")
