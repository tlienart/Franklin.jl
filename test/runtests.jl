using JuDoc, Test

# this MUST be run before running the tests otherwise you may get an error
# like "key 0x099191234..." was not found
JuDoc.def_LOC_VARS()
JuDoc.def_GLOB_VARS()
JuDoc.def_GLOB_LXDEFS()

include("jd_paths_vars.jl") # ✅  aug 16, 2018

# MANAGER folder
include("manager/utils.jl") # ✅  oct 12, 2018
println("🍺")

# PARSER folder
println("PARSER/MD+LX")
include("parser/markdown+latex.jl") # ✅  oct 12, 2018
println("🍺")
println("PARSER/HTML")
include("parser/html.jl") # ✅ oct 12, 2018
println("🍺")

# CONVERTER folder
println("CONVERTER/MD")
include("converter/markdown.jl") # ✅ oct 12, 2018
println("🍺")
println("CONVERTER/HTML")
include("converter/html.jl")     # ✅ oct 12, 2018
println("🍺")
