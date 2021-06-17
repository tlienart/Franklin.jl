@def mathjax = true

# Mathjax v3

## Setup

You'll need to add the following lines in your layout (and discard KaTeX ones if there are any to avoid clashes):

```html
<script>
MathJax = {
  tex: {inlineMath: [['\\(', '\\)']]},
  svg: {fontCache: 'global'}
};
</script>
<script id="MathJax-script" async src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-svg.js"></script>
```

## Demos

When $a \neq 0$, there are two solutions to $ax^2+bx+c=0$ and they are

$$
  x = {-b \pm \sqrt{b^2-4ac} \over 2a}
$$

## The Lorenz Equations

\begin{align}
    \dot{x} &= \sigma(y-x) \\
    \dot{y} &= \rho x - y - xz \\
    \dot{z} &= -\beta z + xy
\end{align}

## Cauchy Schwarz

\[
    \left( \sum_{k=1}^n a_k b_k \right)^{\!\!2} \leq
    \left( \sum_{k=1}^n a_k^2 \right) \left( \sum_{k=1}^n b_k^2 \right)
\]

## Cross product

\[
  \mathbf{V}_1 \times \mathbf{V}_2 =
   \begin{vmatrix}
    \mathbf{i} & \mathbf{j} & \mathbf{k} \\
    \frac{\partial X}{\partial u} & \frac{\partial Y}{\partial u} & 0 \\
    \frac{\partial X}{\partial v} & \frac{\partial Y}{\partial v} & 0 \\
   \end{vmatrix}
\]

## Rogers-Ramanujan

\[
  1 +  \frac{q^2}{(1-q)}+\frac{q^6}{(1-q)(1-q^2)}+\cdots =
    \prod_{j=0}^{\infty}\frac{1}{(1-q^{5j+2})(1-q^{5j+3})},
     \quad\quad \text{for $|q| &lt; 1$}.
\]

## Maxwell

\begin{align}
  \nabla \times \vec{\mathbf{B}} -\, \frac1c\, \frac{\partial\vec{\mathbf{E}}}{\partial t} &= \frac{4\pi}{c}\vec{\mathbf{j}} \\
  \nabla \cdot \vec{\mathbf{E}} &= 4 \pi \rho \\
  \nabla \times \vec{\mathbf{E}}\, +\, \frac1c\, \frac{\partial\vec{\mathbf{B}}}{\partial t} &= \vec{\mathbf{0}} \\
  \nabla \cdot \vec{\mathbf{B}} &= 0
\end{align}

## More inline

Finally, while display equations look good for a page of samples, the
ability to mix math and text in a paragraph is also important.  This
expression $\sqrt{3x-1}+(1+x)^2$ is an example of an inline equation.  As
you see, MathJax equations can be used this way as well, without unduly
disturbing the spacing between lines.
