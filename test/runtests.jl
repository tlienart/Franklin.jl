using JuDoc, Random, Test
const J = JuDoc

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
include("converter/hyperref.jl")
println("🍺")

println("CONVERTER/HTML")
include("converter/html.jl")
println("🍺")

println("CONVERTER/LX")
include("converter/lx_input.jl")
println("🍺")

println("INTEGRATION")
include("converter/integration.jl")
println("PRE-RENDERING")
include("converter/js_prerender.jl")
println("🥳  🥳  🥳  🥳 ")
