module JuDoc

using JuDocTemplates

using Markdown
using Markdown: htmlesc
using Dates # see jd_vars
using DelimitedFiles: readdlm
using OrderedCollections
using Pkg
using DocStringExtensions: SIGNATURES, TYPEDEF

import Logging
import LiveServer
import Base.push!
import NodeJS
import Literate
import HTTP

export serve, publish, cleanpull, newsite, optimize, jd2html, literate_folder, verify_links

# -----------------------------------------------------------------------------
#
# CONSTANTS
#

"""Big number when we want things to be far."""
const BIG_INT = typemax(Int)

"""Flag for debug mode."""
const DEBUG_MODE = Ref(false)

"""Flag for the initial pass over pages"""
const FULL_PASS = Ref(true)

"""Flag for re-evaluation of all code blocks"""
const FORCE_REEVAL = Ref(false)

"""Flag for error suppression mode (set and unset in optimize only)."""
const SUPPRESS_ERR = Ref(false)

"""Dict to keep track of languages and how comments are indicated and their extensions."""
const CODE_LANG = LittleDict{String,NTuple{2,String}}(
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
const PageVars = LittleDict{String,Pair{K,NTuple{N, DataType}} where {K, N}}

"""Relative path to the current file being processed by JuDoc."""
const CUR_PATH = Ref("")

"""Relative path to the last with eval'd code blocks (to know what's in scope)."""
const CUR_PATH_WITH_EVAL = Ref("")

"""Shorter name for a type that we use everywhere"""
const AS = Union{String,SubString{String}}

"""Convenience constants for an automatic message to add to code files."""
const MESSAGE_FILE_GEN     = "This file was generated, do not modify it."
const MESSAGE_FILE_GEN_LIT = "# $MESSAGE_FILE_GEN\n\n"
const MESSAGE_FILE_GEN_JMD = "# $MESSAGE_FILE_GEN # hide\n"

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
include("parser/md_validate.jl")
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
include("converter/html_functions.jl")
include("converter/html.jl")
# > fighting Julia's markdown parser
include("converter/link_fixer.jl")
# > javascript
include("converter/js_prerender.jl")

# FILE PROCESSING
include("jd_paths.jl")
include("jd_vars.jl")

# FILE AND DIR MANAGEMENT
include("manager/rss_generator.jl")
include("manager/dir_utils.jl")
include("manager/file_utils.jl")
include("manager/judoc.jl")
include("manager/post_processing.jl")

# MISC UTILS
include("misc_utils.jl")
include("misc_html.jl")

# ERROR TYPES
include("error_types.jl")

# INTEGRATION
include("integration/literate.jl")

end # module
