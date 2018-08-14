using JuDoc, Test

include("jd_paths.jl") # ✅ aug 14, 2018 // RUN ONLY ONCE
include("jd_vars.jl")  # ✅ aug 14, 2018

# >> MANAGER folder
include("manager/utils.jl")

# >> PARSER folder
# >> >> MARKDOWN

include("parser/markdown.jl") # ✅ aug 13, 2018
include("parser/latex.jl")    # ✅ aug 14, 2018
