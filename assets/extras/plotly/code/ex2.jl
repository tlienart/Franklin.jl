# This file was generated, do not modify it. # hide
using PlotlyJS
p=plot(
     scatter(x=1:10, y=rand(10), mode="markers"),
     Layout(title="Responsive Plots")
     )
savejson(p, joinpath(@OUTPUT, "plotlyex.json"))  # savejson is an alternative to savefig # hide
# PlotlyBase.json (also exported by PlotlyJS) often gives a smaller json compared to PlotlyJS.savefig # hide