+++
title = "WGLMakie + JSServe"
+++

```julia:ex
using WGLMakie, JSServe
io = IOBuffer()
println(io, "~~~")
show(io, MIME"text/html"(), Page(exportable=true, offline=true))
app = JSServe.App() do
    return DOM.div(
        scatter(1:4),
        surface(rand(4, 4)),
        JSServe.Slider(1:3)
    )
end
show(io, MIME"text/html"(), app)
println(io, "~~~")
println(String(take!(io)))
```
\textoutput{ex}
