using Pkg; Pkg.activate("."); using JuDoc, Test

# >> PARSER folder
# >> >> MARKDOWN

include("parser/markdown.jl") # ✅ aug 13, 2018
include("parser/latex.jl")    #
