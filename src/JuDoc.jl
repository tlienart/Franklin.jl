module JuDoc

using Markdown
using Dates # see jd_vars
using Random

# a number we don't expect to take over with the number of tokens etc...
# basically acts as `Inf` with Int type (Int32 or Int64 is fine)
const BIG_INT = 100_000_000
const JD_PID_FILE = ".__jdpid_tmp__"
const JD_LEN_RANDSTRING = 4 # make this longer if you think you'll collide...

# PARSING
include("parser/tokens.jl")
include("parser/find_tokens.jl")
include("parser/block_utils.jl")
# > latex
include("parser/latex/tokens_lx.jl")
include("parser/latex/find_lxblocks.jl")
include("parser/latex/resolve_lxcoms.jl")
include("parser/latex/resolve_lxrefs.jl")
# > markdown
include("parser/tokens_md.jl")
# > html
include("parser/tokens_html.jl")

# CONVERSION
# > utils
include("converter/hblocks.jl")
include("converter/hfuns.jl")
# > markdown
include("converter/conv_md.jl")
# > html
include("converter/conv_html.jl")


# FILE PROCESSING
include("jd_paths.jl")
include("jd_vars.jl")

# FILE AND DIR MANAGEMENT
include("manager/dir_utils.jl")
include("manager/file_utils.jl")
include("manager/judoc.jl")

# MISC UTILS
include("misc_utils.jl")

end # module
