module JuDoc

using JuDocTemplates

using Markdown
using Dates # see jd_vars

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
const JD_DEBUG = Ref(false)

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

"""Path to the JuDoc repo."""
const JUDOC_PATH = splitdir(pathof(JuDoc))[1] # .../JuDoc/src

"""Path to some temporary folder that will be used by JuDoc."""
const TEMPL_PATH = joinpath(JUDOC_PATH, "templates")

# copied from Base/path.jl
if Sys.isunix()
    """Indicator for directory separation on the OS."""
    const PATH_SEP = "/"
elseif Sys.iswindows()
    const PATH_SEP = "\\"
else
    error("Unhandled OS")
end

"""Type of the containers for page variables."""
const JD_VAR_TYPE = Dict{String,Pair{K,NTuple{N, DataType}} where {K, N}}

"""Relative path to the current file being processed."""
const JD_CURPATH = Ref("")

# -----------------------------------------------------------------------------

include("build.jl") # check if user has Node/minify

# PARSING
include("parser/tokens.jl")
include("parser/ocblocks.jl")
# > latex
include("parser/tokens_lx.jl")
include("parser/lxblocks.jl")
# > markdown
include("parser/tokens_md.jl")
# > html
include("parser/tokens_html.jl")
include("parser/hblocks.jl")

# CONVERSION
# > markdown
include("converter/md_blocks.jl")
include("converter/md_utils.jl")
include("converter/md.jl")
# > latex
include("converter/lx.jl")
# > html
include("converter/html_hblocks.jl")
include("converter/html_hfuns.jl")
include("converter/html.jl")
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

end # module
