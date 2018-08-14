module JuDoc

using Markdown: html

const BIG_INT = 100_000_000

# PARSING

include("parser/tokens.jl")
include("parser/find_tokens.jl")

include("parser/latex/patterns.jl")
include("parser/latex/tokens.jl")
include("parser/latex/resolve_latex.jl")

include("parser/markdown/patterns.jl")
include("parser/markdown/tokens.jl")
include("parser/markdown/find_blocks.jl")

include("parser/html/tokens.jl")
include("parser/html/find_blocks.jl")

# CONVERSION

include("converter/markdown.jl")

# FILE PROCESSING

include("jd_paths.jl")
include("jd_vars.jl")

end # module
