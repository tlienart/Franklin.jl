module JuDoc

export judoc

include("jd_paths.jl")
include("jd_vars.jl")

include("conv/block_patterns.jl")
include("conv/find_replace_md.jl")
include("conv/find_replace_html.jl")
include("conv/process_files.jl")

end # module
