using JuDoc, Test

include("jd_paths.jl") # ✅ aug 16, 2018 // RUN ONLY ONCE
include("jd_vars.jl")  # ✅ aug 16, 2018

# MANAGER folder
include("manager/utils.jl") # 🚫 sep 3, 2018

# PARSER folder
# >> MARKDOWN
include("parser/markdown+latex.jl") # ✅ sep 3, 2018

# >> HTML
include("parser/html.jl") # 🚫 sep 3, 2018

# CONVERTER folder
include("converter/markdown.jl") # ✅ sep 3, 2018
