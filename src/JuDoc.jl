module JuDoc

using JuDocTemplates

using Markdown
using Dates # see jd_vars
using DelimitedFiles: readdlm

import LiveServer

using DocStringExtensions: SIGNATURES, TYPEDEF

export serve, publish, cleanpull, newsite, optimize

# -----------------------------------------------------------------------------
#
# CONSTANTS
#

"""Big number when we want things to be far."""
const BIG_INT = typemax(Int)

"""Flag for debug mode."""
const DEBUG_MODE = Ref(false)

"""Dict to keep track of languages and how comments are indicated and their extensions."""
const CODE_LANG = Dict{String,NTuple{2,String}}(
    "c"          => (".c",    "//"),
    "cpp"        => (".cpp",  "//"),
    "fortran"    => (".f90",  "!"),
    "go"         => (".go",   "//"),
    "javascript" => (".js",   "//"),
    "julia"      => (".jl",   "#"),
    "julia-repl" => (".jl",   "#"),
    "lua"        => (".lua",  "--"),
    "matlab"     => (".m",    "%"),
    "python"     => (".py",   "#"),
    "r"          => (".r",    "#"),
    "toml"       => (".toml", "#"),
    )

# copied from Base/path.jl
if Sys.isunix()
    """Indicator for directory separation on the OS."""
    const PATH_SEP = "/"
elseif Sys.iswindows()
    const PATH_SEP = "\\"
else
    error("Unhandled OS")
end

"""Type of the containers for page variables (local and global)."""
const PageVars = Dict{String,Pair{K,NTuple{N, DataType}} where {K, N}}

"""Relative path to the current file being processed by JuDoc."""
const CUR_PATH = Ref("")

# -----------------------------------------------------------------------------

include("build.jl") # check if user has Node/minify

# PARSING
include("parser/tokens.jl")
include("parser/ocblocks.jl")
# > latex
include("parser/lx_tokens.jl")
include("parser/lx_blocks.jl")
# > markdown
include("parser/md_tokens.jl")
include("parser/md_chars.jl")
# > html
include("parser/html_tokens.jl")
include("parser/html_blocks.jl")

# CONVERSION
# > markdown
include("converter/md_blocks.jl")
include("converter/md_utils.jl")
include("converter/md.jl")
# > latex
include("converter/lx.jl")
include("converter/lx_simple.jl")
# > html
include("converter/html_blocks.jl")
include("converter/html_functions.jl")
include("converter/html.jl")
# > fighting Julia's markdown parser
include("converter/fixer.jl")
# > javascript
include("converter/js_prerender.jl")

# FILE PROCESSING
include("jd_paths.jl")
include("jd_vars.jl")

# FILE AND DIR MANAGEMENT
include("manager/dir_utils.jl")
include("manager/file_utils.jl")
include("manager/judoc.jl")
include("manager/post_processing.jl")

# MISC UTILS
include("misc_utils.jl")
include("misc_html.jl")

# ERROR TYPES
include("error_types.jl")

end # module
