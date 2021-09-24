# This file was generated, do not modify it. # hide
using PyPlot
figure(figsize=(8,6))
plot(rand(5), rand(5))
savefig(joinpath(@OUTPUT, "ex_outpath_1.svg"))
