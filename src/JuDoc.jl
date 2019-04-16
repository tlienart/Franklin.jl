module JuDoc

using JuDocTemplates

using Markdown
using Dates # see jd_vars
using Random
using Highlights
using LiveServer

const BIG_INT = typemax(Int)
const JD_LEN_RANDSTRING = 4 # make this longer if you think you'll collide...
const JD_SERVE_FIRSTCALL = Ref(true)

export serve, publish, cleanpull, newsite, optimize

const HIGHLIGHT = Dict{String,Pair{String,Any}}(
    "fortran"    => "!" => Lexers.FortranLexer,
    "julia-repl" => "#" => Lexers.JuliaConsoleLexer,
    "julia"      => "#" => Lexers.JuliaLexer,
    "matlab"     => "%" => Lexers.MatlabLexer,
    "r"          => "#" => Lexers.RLexer,
    "toml"       => "#" => Lexers.TOMLLexer)

const JUDOC_PATH = splitdir(pathof(JuDoc))[1] # .../JuDoc/src
const TEMPL_PATH = joinpath(JUDOC_PATH, "templates")

# copied from Base/path.jl
if Sys.isunix()
    const PATH_SEP = "/"
elseif Sys.iswindows()
    const PATH_SEP = "\\"
else
    error("Unhandled OS")
end

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
