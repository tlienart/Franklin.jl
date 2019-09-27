using JuDoc, Test, Markdown
const J = JuDoc
const D = joinpath(dirname(dirname(pathof(JuDoc))), "test", "_dummies")

# NOTE this first file MUST be included before running the rest of the tests
# otherwise you may get an error like "key 0x099191234..." was not found or
# saying that the key :in doesn't exist or something along those lines
include("jd_paths_vars.jl"); include("test_utils.jl")

include("misc.jl")

# MANAGER folder
include("manager/utils.jl")
println("🍺")

# PARSER folder
println("PARSER/MD+LX")
include("parser/markdown+latex.jl")
include("parser/markdown-extra.jl")
include("parser/footnotes.jl")
println("🍺")
println("PARSER/HTML")
include("parser/html.jl")
println("🍺")

# CONVERTER folder
println("CONVERTER/MD")
include("converter/markdown.jl")
include("converter/markdown2.jl")
include("converter/markdown3.jl")
include("converter/hyperref.jl")
println("🍺")
println("CONVERTER/HTML")
include("converter/html.jl")
println("🍺")

println("CONVERTER/LX")
include("converter/eval.jl")
include("converter/lx_input.jl")
include("converter/lx_simple.jl")
println("🍺")

println("INTEGRATION")
include("global/cases1.jl")
include("global/cases2.jl")
include("global/ordering.jl")

begin
    # create temp dir to do complete integration testing (has to be here in order
    # to locally play nice with node variables etc, otherwise it's a big headache)
    p = joinpath(D, "..", "__tmp");
    # after errors, this may not have been deleted properly
    isdir(p) && rm(p; recursive=true, force=true)
    # make dir, go in it, do the tests, then get completely out (otherwise windows
    # can't delete the folder)
    mkdir(p); cd(p);
    include("global/postprocess.jl");
    cd(joinpath(D, ".."))
    # clean up
    rm(p; recursive=true, force=true)
end
cd(dirname(dirname(pathof(JuDoc))))
println("😅 😅 😅 😅")
