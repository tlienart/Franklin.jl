# Syntax

This page is about the modified markdown syntax that is used in JuDoc.
For the HTML templating syntax, see [Templating](@ref).

A good way to become familiar with the JuDoc syntax is to generate a test-website and modify its `index.md` as explained in [Quickstart](@ref).

## Basics

The basic syntax corresponds to standard Markdown.
So for instance `**bold text**` will do just what you think, headers are marked with `#` etc.
The [Markdown Cheatsheet](https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet) is a great resource to get started.

### Maths

For maths elements the usage is similar to LaTeX:

* inline math with `$ ... $` e.g.:

```judoc
the function $ f(x)=\sin(x) $ is periodic
```

* display math with `$$ ... $$` or `\[ ... \]` e.g.:

```judoc
the identity
\[ \exp(i\pi)+1=0 \]
is nice
```

* aligned math with `\begin{align} ... \end{align}` e.g.:

```judoc
\begin{align}
a&=5 \\
b&=7 \end{align}
```

* also aligned math with `\begin{eqnarray} ... \end{eqnarray}` e.g.:

```judoc
\begin{eqnarray}
a &=& 5 \\
b &=& 7 \end{eqnarray}
```

!!! note

    In LaTeX use of `eqnarray` tends to be discouraged due to possible interference with array column spacing. In JuDoc this will not happen. However it is identical with LaTeX in that the spacing around the `=` in a `eqnarray` is larger than in an `align`.

### Raw HTML

You can inject raw HTML by using `~~~ ... ~~~` which can be useful if, for instance, you occasionally want to have a specific layout such as text next to an image:

```judoc
Some text here in the "standard" layout then you can inject raw HTML:

~~~
<div class="row">
  <div class="container">
    <img class="left" src="assets/infra/rndimg.jpg">
    <p> Marine iguanas are truly splendid creatures. </p>
    <p> Evolution is cool. </p>
    <div style="clear: both"></div>      
  </div>
</div>
~~~

and subsequently continue with the standard layout.
```

## LaTeX commands

JuDoc allows the definition of LaTeX-like commands which can be particularly useful for repeating elements be it in or out of math environments.
Definition of commands is as in LaTeX (with the constraint that you **must** use `\newcommand`, braces and no space between them).

**Example 1**: a command to get a ``\mathbb R`` in math environments:

```judoc
\newcommand{\R}{\mathbb R}

Let $f:\R\to\R$ a function...
```

**Example 2**: a command to get a ``\langle x, y \rangle`` in math environments:

```judoc
\newcommand{\scal}[1]{\left\langle #1 \right\rangle}
```

**Example 3**: a command to change the colour of the text outside of a math environment (inside a math environment you can use `\textcolor`, we're using a different name here so that these two don't clash since commands defined in JuDoc take precedence):

```judoc
\newcommand{\col}[2]{~~~ <font color="#1">#2</font> ~~~}

And then you can use \col{tomato}{colours} in your text.
```





## Div Blocks

## Page variables
