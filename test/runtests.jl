using JuDoc, Test

include("jd_paths.jl") # ✅ aug 16, 2018 // RUN ONLY ONCE
include("jd_vars.jl")  # ✅ aug 16, 2018

# MANAGER folder
include("manager/utils.jl") # 🚫 sep 3, 2018
println("🍺")

# PARSER folder
println("nPARSER/MD+LX")
include("parser/markdown+latex.jl") # ✅ sep 3, 2018
println("🍺")
println("PARSER/HTML")
include("parser/html.jl") # ✅ sep 3, 2018
println("🍺")

# CONVERTER folder
println("CONVERTER/MD")
include("converter/markdown.jl") # ✅ sep 3, 2018
println("🍺")
println("CONVERTER/HTML")
include("converter/html.jl")     # ✅ sep 3, 2018
println("🍺")
