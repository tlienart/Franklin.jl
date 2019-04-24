# Syntax

This page is about the modified markdown syntax that is used in JuDoc.
For the HTML templating syntax, see [Templating](@ref).

A good way to become familiar with the JuDoc syntax is to generate a test-website and modify its `index.md` as explained in the [Quickstart](@ref) tutorial.
Most of what is presented here is also shown in that example.

**Content**:

* [Basic syntax](#Basics-1)
  * [maths](#Maths-1)
  * [div blocks](#Div-blocks-1)
  * [using raw HTML](#Using-raw-HTML-1)
* [LaTeX commands](#LaTeX-commands-1)
  * [Whitespaces](#Whitespaces-1)
  * [Nesting](#Nesting-1)
  * [Hyper-references](#Hyper-references-1)
* [Insertions](#Insertions-1)
* [Page variables](#Page-variables-1)

## Basics

The basic syntax corresponds to standard markdown and the [markdown cheatsheet](https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet) is a great resource, in particular:

* how to [insert images](https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet#images),
* how to [insert code](https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet#code-and-syntax-highlighting),
* how to [insert tables](https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet#tables).

One key difference with Git Flavored Markdown (GFM) is that inline HTML _should not be used_ (see the section on injecting HTML below).

### Maths

For maths elements the usage is similar to standard LaTeX; whitespaces and new-lines don't matter. If you want to write a dollar symbol, you can escape it like so: `\$`.

* inline math with `$ ... $` e.g.:

```judoc
the function $ f(x)=\sin(x) $ is periodic, this is a dollar sign: \$.
```

* display math with `$$ ... $$` or `\[ ... \]` e.g.:

```judoc
the identity
\[ \exp(i\pi)+1=0 \]
is nice
```

* display + aligned math (1) with `\begin{align} ... \end{align}` e.g.:

```judoc
\begin{align}
a&=5 \\
b&=7 \end{align}
```

* display + aligned math (2) with `\begin{eqnarray} ... \end{eqnarray}` e.g.:

```judoc
\begin{eqnarray}
a &=& 5 \\
b &=& 7 \end{eqnarray}
```

!!! note

    In LaTeX use of `eqnarray` tends to be discouraged due to possible interference with array column spacing. In JuDoc this will not happen. However it is identical with LaTeX in that the spacing around the `=` in a `eqnarray` is larger than in an `align`.

!!! note

    Currently all display-math equations are numbered by default.

### Div blocks

In order to locally style your content, you can use `@@divname ... @@` which will wrap some content in a `<div class="divname"> ... </div>` block which you can style as you wish in your CSS stylesheet.
For instance, you may want to highlight some content with a light-yellow background, you can do this with:

```judoc
Some text then

@@important
Some important content
@@

and the rest of your text
```

and then, in your CSS, you could use

```css
.important {
  background-color: lemonchiffon;
  padding-left: 0.5em;
  padding-top: 0.7em;
  padding-bottom: 0.5em;
  border-radius: 5px;
}
```

which will look like

!!! important

    Some important content

These div blocks can be nested as in standard HTML.

### Using raw HTML

You can inject HTML by using `~~~ ... ~~~` which can be useful if, for instance, you occasionally want to have a specific layout such as text next to an image:

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

!!! note

    In a raw HTML, you cannot use markdown, maths etc. For this reason, if you can, it is often preferable to use nested `@@divname...` blocks instead of raw HTML since those _can_ have markdown, maths, etc. in them.

## LaTeX commands

JuDoc allows the definition of LaTeX-like commands which can be particularly useful for repeating elements be it in or out of math environments.

Definition of commands is as in LaTeX (with the constraint that you _must_ use the `\newcommand{...}[...]{...}` format (see examples below).

**Example 1**: a command to get a ``\mathbb R`` in math environments:

```judoc
\newcommand{\R}{\mathbb R}

Let $f:\R\to\R$ a function...
```

**Example 2**: a command to get a ``\langle x, y \rangle`` in math environments:

```judoc
\newcommand{\scal}[1]{\left\langle #1 \right\rangle}
```

**Example 3**: a command to change the colour of the text outside of a math environment (note that inside a math environment you can use `\textcolor` which is defined in KaTeX; I'm using a different name here so that these two don't clash since commands defined in JuDoc take precedence):

```judoc
\newcommand{\col}[2]{~~~ <font color="#1">#2</font> ~~~}

And then you can use \col{tomato}{colours} in your text and
$$x + \textcolor{blue}{y} + z$$
in your maths.
```

### Whitespaces

In a JuDoc newcommand, to refer to an argument, you can use `#1` or `!#1`.
There is a subtle difference: the first one introduces a space left of the argument (this allows to avoid ambiguous commands in general) and the second one does not.
In general whitespaces are irrelevant and will not show up and so the usual `#1` is the recommended setting.
However, there are cases where the whitespace does appear and you don't want it to (e.g. if the command is preceded by something).
In those cases, and provided there is no ambiguity (e.g.: chaining of commands), you can use `!#1` which will *not* insert the whitespace.
As an example,

```judoc
\newcommand{\pathwith}[1]{`/usr/local/bin/#1`}
\newcommand{\pathwithout}[1]{`/usr/local/bin/!#1`}
```

Using `\pathwith{hello}` will give `/usr/local/bin/ hello` which would be inappropriate whereas `\pathwithout{hello}` will give `usr/local/hello`.

### Nesting

Using commands can be nested, again as in LaTeX and, moreover, you can throw in some markdown.
Here is a somewhat more sophisticated example for a "definition" environment:

```judoc
\newcommand{\definition}[2]{@@definition **Definition**: (_!#1_) #2 @@}

\definition{angle between vectors}{
  Let $x, y \in \R^n$ denote two real vectors and let $\scal{\cdot, \cdot}$ denote
  the inner product of two vectors. Then, the angle $\theta$ between $x$ and $y$ is
  given by $$ \cos(\theta) = {\scal{x,y}\over \scal{x,x} \scal{y,y}} $$ }
```

with CSS

```css
.definition {
    background-color: aliceblue;
    border-left: 5px solid cornflowerblue;
    border-radius: 10px;
    padding: 10px;
}
```

it will look like

![](../assets/ex-definition.png)

### Hyper-references

## Insertions

## Page variables
