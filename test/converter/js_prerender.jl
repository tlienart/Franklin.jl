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
