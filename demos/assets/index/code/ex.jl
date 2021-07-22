# This file was generated, do not modify it. # hide
using WGLMakie, JSServe
WGLMakie.activate!()

io = IOBuffer()
fig(o) = show(io, MIME"text/html"(), o)

println(io, "~~~")
Page(exportable=true, offline=true) |> fig
scatter(1:4) |> fig
surface(rand(4, 4)) |> fig
JSServe.Slider(1:3) |> fig
println(io, "~~~")
println(String(take!(io)))