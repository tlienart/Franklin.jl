using Franklin, Test, Markdown, Dates, Random, Literate
const J = Franklin
const R = @__DIR__
const D = joinpath(dirname(dirname(pathof(Franklin))), "test", "_dummies")

# NOTE this first file MUST be included before running the rest of the tests
# otherwise you may get an error like "key 0x099191234..." was not found or
# saying that the key :in doesn't exist or something along those lines
include("frank_paths_vars.jl"); include("test_utils.jl")

include("misc.jl")

# MANAGER folder
include("manager/utils.jl")
include("manager/rss.jl")
include("manager/config.jl")
println("🍺")

# PARSER folder
println("PARSER/MD+LX")
include("parser/1-tokenize.jl")
include("parser/2-blocks.jl")
include("parser/markdown+latex.jl")
include("parser/markdown-extra.jl")
include("parser/footnotes+links.jl")
println("🍺")

# ERRORS
println("Errors")
include("errors/context.jl")
println("🍺")

# EVAL
println("EVAL")
include("eval/module.jl")
include("eval/run.jl")
include("eval/io.jl")
include("eval/codeblock.jl")

# CONVERTER folder
println("CONVERTER/MD")
include("converter/markdown.jl")
include("converter/markdown2.jl")
include("converter/markdown3.jl")
include("converter/markdown4.jl")
include("converter/hyperref.jl")
println("🍺")
println("CONVERTER/HTML")
include("converter/html.jl")
include("converter/html2.jl")
println("🍺")
println("CONVERTER/EVAL")
include("converter/eval.jl")
println("🍺")
println("CONVERTER/LX")
include("converter/lx_input.jl")
include("converter/lx_simple.jl")
println("🍺")

println("GLOBAL")
include("global/cases1.jl")
include("global/cases2.jl")
include("global/ordering.jl")
include("global/html_esc.jl")

begin
    # create temp dir to do complete integration testing (has to be here in
    # order to locally play nice with node variables etc, otherwise it's a big
    # headache)
    p = joinpath(D, "..", "__tmp");
    # after errors, this may not have been deleted properly
    isdir(p) && rm(p; recursive=true, force=true)
    # make dir, go in it, do the tests, then get completely out (otherwise
    # windows can't delete the folder)
    mkdir(p); cd(p);
    include("global/postprocess.jl");
    include("global/rss.jl")
    cd(p)
    include("global/eval.jl")
    cd(joinpath(D, ".."))
    # clean up
    rm(p; recursive=true, force=true)
end
cd(dirname(dirname(pathof(Franklin))))

println("INTEGRATION")
include("integration/literate.jl")

flush_td()
cd(joinpath(dirname(dirname(pathof(Franklin)))))

println("COVERAGE")
include("coverage/extras1.jl")

println("😅 😅 😅 😅")
