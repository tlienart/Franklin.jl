using Pkg; Pkg.activate(".")
using JuDoc, Test

# >> PARSER folder
# >> >> MARKDOWN

include("parser/markdown.jl")
include("parser/latex.jl")
