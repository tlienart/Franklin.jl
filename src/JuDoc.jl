module JuDoc

export judoc

include("jd_paths.jl")
include("jd_vars.jl")

include("md_parse/MDBlock.jl")
include("md_parse/maths.jl")
include("md_parse/misc.jl")

include("html_parse/process_blocks.jl")
include("html_parse/blocks_sqbr.jl")
include("html_parse/blocks_braces.jl")
include("html_parse/tools.jl")

include("process_files.jl")

end # module
