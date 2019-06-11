@testset "Generation and optimisation" begin
    isdir("basic") && rm("basic", recursive=true, force=true)
    newsite("basic")

    if get(ENV, "CI", "false") == "true"
        import Pkg; Pkg.add("LinearAlgebra"); using LinearAlgebra;
    end

    serve(single=true)
    # ---------------
    @test all(isdir, ("assets", "css", "libs", "pub", "src"))
    @test all(isfile, ("index.html",
                 map(e->joinpath("pub", "menu$e.html"), 1:3)...,
                 map(e->joinpath("css", e), ("basic.css", "judoc.css"))...,
                 )
              )
    # ---------------
    if JuDoc.JD_CAN_MINIFY
        presize1 = stat(joinpath("css", "basic.css")).size
        presize2 = stat("index.html").size
        optimize(prerender=false)
        @test stat(joinpath("css", "basic.css")).size < presize1
        @test stat("index.html").size < presize2
    end
    # ---------------
    # change the prepath
    index = read("index.html", String)
    @test occursin("=\"/css/basic.css", index)
    @test occursin("=\"/css/judoc.css", index)
    @test occursin("=\"/libs/highlight/github.min.css", index)
    @test occursin("=\"/libs/katex/katex.min.css", index)

    optimize(minify=false, prerender=false, prepath="prependme")
    index = read("index.html", String)
    @test occursin("=\"/prependme/css/basic.css", index)
    @test occursin("=\"/prependme/css/judoc.css", index)
    @test occursin("=\"/prependme/libs/highlight/github.min.css", index)
    @test occursin("=\"/prependme/libs/katex/katex.min.css", index)
end

if J.JD_CAN_PRERENDER && J.JD_CAN_HIGHLIGHT
@testset "Prerender" begin
  hs = raw"""
    <!doctype html>
    <html lang=en>
    <meta charset=UTF-8>
    <div class=jd-content>
      <h1>Title</h1>
      <p>Blah</p>
      <p>Consider an invertible matrix \(M\) made of blocks \(A\), \(B\), \(C\) and \(D\) with</p>
      \[ M \quad\!\! =\quad\!\! \begin{pmatrix} A & B \\ C & D \end{pmatrix} \]
      <pre><code class=language-julia >using Test
      # Woodbury formula
      b = 2
      println("hello $b")
      </code></pre>
    </div>
    """
  jskx = J.js_prerender_katex(hs)
  # conversion of `\(M\)` (inline)
  @test occursin("""<span class="katex"><span class="katex-mathml"><math><semantics><mrow><mi>M</mi></mrow>""", jskx)
  # conversion of the equation (display)
  @test occursin("""<span class="katex-display"><span class="katex"><span class="katex-mathml"><math><semantics><mrow><mi>M</mi>""", jskx)
  jshl = J.js_prerender_highlight(hs)
  # conversion of the code
  @test occursin("""<pre><code class="julia hljs"><span class="hljs-keyword">using</span>""", jshl)
  @test occursin(raw"""<span class="hljs-string">"hello <span class="hljs-variable">$b</span>"</span>""", jshl)
end
end # if can prerender
