using JuDoc
@static if VERSION < v"0.7.0-DEV.2005"
    using Base.Test
else
    using Test
end

# NOTE: must be run 1st and *only once*
include("t_jd_paths.jl")

# --- CORE TESTS ---

include("t_md_maths.jl")
include("t_md_misc.jl")

include("t_html_maths_divs.jl")
include("t_html_blocks_sqbr.jl")
include("t_html_blocks_braces.jl")

include("t_jd_vars.jl")
include("t_process_files.jl")
