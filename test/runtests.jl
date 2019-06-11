using JuDoc, Test, Markdown
const J = JuDoc
const D = joinpath(dirname(dirname(pathof(JuDoc))), "test", "_dummies")

# NOTE this first file MUST be included before running the rest of the tests
# otherwise you may get an error like "key 0x099191234..." was not found or
# saying that the key :in doesn't exist or something along those lines
include("jd_paths_vars.jl")

include("misc.jl")

# MANAGER folder
include("manager/utils.jl")
println("🍺")

# PARSER folder
println("PARSER/MD+LX")
include("parser/markdown+latex.jl")
println("🍺")
println("PARSER/HTML")
include("parser/html.jl")
println("🍺")

# CONVERTER folder
println("CONVERTER/MD")
include("converter/markdown.jl")
include("converter/markdown2.jl")
include("converter/hyperref.jl")
println("🍺")

println("CONVERTER/HTML")
include("converter/html.jl")
println("🍺")

println("CONVERTER/LX")
include("converter/lx_input.jl")
println("🍺")

println("INTEGRATION")
include("global/utils.jl")
include("global/cases1.jl")
include("global/cases2.jl")

begin
    # create temp dir to do complete integration testing (has to be here in order
    # to locally play nice with node variables etc, otherwise it's a big headache)
    p = normpath(joinpath(D, "..", "__tmp"));
    isdir(p) && rm(p, recursive=true, force=true)
    mkdir(p); cd(p)
    include("global/postprocess.jl");
    cd(".."); rm(p, recursive=true, force=true)
end

println("🥳  🥳  🥳  🥳 ")
