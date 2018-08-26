module JuDoc

using Markdown
using LinearAlgebra: dot

const BIG_INT = 100_000_000

# PARSING
include("parser/tokens.jl")
include("parser/find_tokens.jl")
include("parser/block_utils.jl")
# > latex
include("parser/latex/patterns.jl")
include("parser/latex/tokens.jl")
include("parser/latex/resolve_latex.jl")
include("parser/latex/find_blocks.jl")
# > markdown
include("parser/markdown/patterns.jl")
include("parser/markdown/tokens.jl")
include("parser/markdown/find_blocks.jl")
# > html
include("parser/html/patterns.jl")
include("parser/html/tokens.jl")
include("parser/html/find_blocks.jl")

# CONVERSION
# > markdown
include("converter/markdown.jl")
# > html
include("converter/html.jl")
include("converter/hfuns.jl")


# FILE PROCESSING

include("jd_paths.jl")
include("jd_vars.jl")

# FILE AND DIR MANAGEMENT

include("manager/misc_utils.jl")
include("manager/dir_utils.jl")
include("manager/file_utils.jl")
include("manager/judoc.jl")

end # module
