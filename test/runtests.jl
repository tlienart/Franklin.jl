using JuDoc, Test

include("jd_paths.jl") # ✅ aug 16, 2018 // RUN ONLY ONCE
include("jd_vars.jl")  # ✅ aug 16, 2018

# MANAGER folder
include("manager/utils.jl") # ✅ aug 31, 2018

# PARSER folder
# >> MARKDOWN

include("parser/markdown.jl") # ✅ aug 19, 2018
include("parser/latex.jl")    # ✅ aug 14, 2018

# >> HTML
include("parser/html.jl") # ✅ aug 15, 2018
