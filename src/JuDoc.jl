module JuDoc

export judoc

include("jd_paths.jl")
include("jd_vars.jl")
include("block_patterns.jl")
include("find_replace_md.jl")
include("find_replace_html.jl")
include("process_files.jl")

end # module
