
<!--
reviewed: 18/4/20
-->

# Divs and Commands

\blurb{Style your content quickly and easily with custom divs, make everything reproducible and maintainable with commands.}

\lineskip

\toc

## Div blocks

In order to locally style your content, you can use `@@divname ... @@` which will wrap the content in a `<div class="divname"> ... </div>` block which you can then style as you wish in your CSS stylesheet.
For instance, you may want to highlight some content with a light yellow background:

```plaintext
Some text then
@@important
  Some important content
@@
```

and then, in your CSS, you could use

```css
.important {
  background-color: lemonchiffon;
  padding: 0.5em;
  margin-bottom: 1em;
}
```

which will look like

@@important
  Some important content
@@

You can do this with multiple classes separating them with a comma: `@@c1,c2 ... @@` for instance, this also works with [tailwind.css](https://tailwindcss.com/) classes: `@@c1,hover:basis-1/2 ... @@` etc.

### Nesting

Such div blocks can be nested as in standard HTML.
The distinction with inserting raw HTML div blocks with the `~~~...~~~` syntax is that the content  of div blocks is processed as well (i.e.: can contain Franklin markdown):

```plaintext
@@important
  Some text;
  @@silly-formatting
    some **silly** text with $2x+4=y$.
  @@
  and more text.
@@
```

@@important
  Some text;
  @@silly-formatting
    some **silly** text with $2x+4=y$.
  @@
  and more text.
@@

## LaTeX-like commands

Franklin allows the definition of commands using a LaTeX-like syntax.
This can be particularly useful for repeating elements or styling inside or outside of the maths environment.

To define a command, you **must** use the following syntax:

```plaintext
\newcommand{\name}[...]{...}
             -1-   -2-  -3-
```

where:

@@flist
1. the first bracket is the _command name_, starting with a backslash and _only made out of letters_ (lower or upper case),
1. the second (optional) bracket indicates the _number of arguments_, if none is set the command does not take arguments,
1. the third bracket indicates the _definition of the command_ calling `#k` to insert the $k$-th argument.
@@

As in LaTeX, command definitions can be anywhere as long as they appear before they are used.
If you want a command to be available on all your pages, put the definition in the `config.md` file.

\note{Franklin currently cannot just take the content of a `.tex` document and convert it, this may be (partially) supported in the future if it is deemed useful. Mainly it would require pre-defining all standard commands such as `\textbf`, `\section`, etc.}

### Math examples

If you end up writing a lot of equations on your site, defining commands can become rather useful:

```plaintext
\newcommand{\R}{\mathbb R}

Let $f:\R\to\R$ a function...
```

\newcommand{\R}{\mathbb R}
Let $f:\R\to\R$ a function...

```plaintext
\newcommand{\scal}[1]{\left\langle #1 \right\rangle}

$$ \mathcal W_\psi[f] = \int_\R f(s)\psi(s)\mathrm{d}s = \scal{f,\psi} $$
```

\newcommand{\scal}[1]{\left\langle #1 \right\rangle}
$$ \mathcal W_\psi[f] = \int_\R f(s)\psi(s)\mathrm{d}s = \scal{f,\psi} $$

### Text examples

Commands can also be useful outside of the maths environment.
For instance, you could define a command to quickly set the style of some text:

```html
\newcommand{\styletext}[2]{~~~<span style="#1">#2</span>~~~}

Here is \styletext{color:magenta;font-size:14px;}{formatted text}.
```

\newcommand{\styletext}[2]{~~~<span style="#1">#2</span>~~~}

Here is \styletext{color:magenta;font-size:14px;font-variant:small-caps;}{formatted text}.

### Nesting examples

Commands are resolved recursively which means that they can be nested and their definition can contain further Franklin markdown (again this is similar to how LaTeX works).

Consider for instance:

```plaintext
\newcommand{\norm}[2]{\left\|#1\right\|_{#2}}
\newcommand{\anorm}[1]{\norm{#1}{1}}
\newcommand{\bnorm}[1]{\norm{#1}{2}}

Let $x\in\R^n$, there exists $0 < C_1 \le C_2$ such that

$$ C_1 \anorm{x} \le \bnorm{x} \le C_2\anorm{x}. $$
```

\newcommand{\norm}[2]{\left\|#1\right\|_{#2}} <!--_-->
\newcommand{\anorm}[1]{\norm{#1}{1}}
\newcommand{\bnorm}[1]{\norm{#1}{2}}

Let $x\in\R^n$, there exists $0 < C_1 \le C_2$ such that

$$ C_1 \anorm{x} \le \bnorm{x} \le C_2\anorm{x}. $$

As indicated earlier, commands can contain further Franklin markdown that is processed recursively.
For example, here is a more sophisticated example of a "definition" command such that this:

```plaintext
\definition{angle between vectors}{
  Let $x, y \in \R^n$ and let $\scal{\cdot, \cdot}$ denote
  the usual inner product. Then, the angle $\theta$ between
  $x$ and $y$ is given by
  $$ \cos(\theta) = {\scal{x,y}\over \scal{x,x} \scal{y,y}}. $$
}
```

leads to this:

\newcommand{\definition}[2]{@@definition **Definition**: (_!#1_) #2 @@}

\definition{angle between vectors}{
  Let $x, y \in \R^n$ and let $\scal{\cdot, \cdot}$ denote
  the usual inner product. Then, the angle $\theta$ between $x$ and $y$ is
  given by $$ \cos(\theta) = {\scal{x,y}\over \scal{x,x} \scal{y,y}}. $$
}

To do this, you would define the command:

```html
\newcommand{\definition}[2]{
  @@definition
  **Definition**: (_!#1_)
  #2
  @@
}
```

and specify the styling of the `definition` div in your CSS:

```css
.definition {
  background-color: aliceblue;
  border-left: 5px solid cornflowerblue;
  border-radius: 10px;
  padding: 10px;
  margin-bottom: 1em;
}
```

### Whitespaces

In a Franklin `newcommand`, to refer to an argument you can use `#k` or `!#k`.
There is a small difference: the first one _introduces a space_ left of the argument while the second one does not.

In general, whitespaces are irrelevant and will not show up on the rendered webpage so the usual `#k` is the recommended usage.
This helps avoid some ambiguities when resolving a chain of nested commands.

There are however cases where you do not want this because the whitespace does, in fact, show up.
In such cases use `!#k` (assuming it's not ambiguous).

Consider for instance:

```plaintext
\newcommand{\pathwith}[1]{`/usr/local/bin/#1`}
\newcommand{\pathwithout}[1]{`/usr/local/bin/!#1`}

Here \pathwith{hello} is no good whereas \pathwithout{hello} is.
```

\newcommand{\pathwith}[1]{`/usr/local/bin/#1`}
\newcommand{\pathwithout}[1]{`/usr/local/bin/!#1`}

Here \pathwith{hello} is no good whereas \pathwithout{hello} is.

### Defining commands globally

If you define commands on a page, the command will be available only on that page; if you wish to define a command that is available on all pages, you should put the definition of the command in your `config.md` file.

## Hyper-references

Three types of hyper-references are supported in Franklin:

@@flist
1. for equations in display mode,
1. for references (bibliography),
1. for specific anchor points on the page.
@@

The syntax for all three is close to that of standard LaTeX.

To style the appearance of the maths or bib links in CSS, use `.franklin-content.eqref a` and `.franklin-content.bibref a` classes; for instance:

```css
.franklin-content .eqref a  {color: blue;}
.franklin-content .bibref a {color: green;}
```

### Equations

To label an equation, just use `\label{some label}` in the math environment and, to refer to it, use `\eqref{some label}`:

```plaintext
Some equation:

$$\exp(i\pi) + 1 = 0 \label{a cool equation}$$

and you can refer to it in the text: equation \eqref{a cool equation}.
```

As in LaTeX, you can refer to several equations in one shot by separating names with commas: `\eqref{some label, some other}` (that also means you cannot use commas in labels).

### References

For references, you can use `\biblabel{short}{name}` to declare a reference which will appear as a clickable link `(name)` or `name` and can be referred to with `short`:

```plaintext
In the text, you may refer to \citep{noether15, bezanson17} while in a bibliography section you would have

* \biblabel{noether15}{Noether (1915)} **Noether**, Korper und Systeme rationaler Funktionen, 1915.
* \biblabel{bezanson17}{Bezanson et al. (2017)} **Bezanson**, **Edelman**, **Karpinski** and **Shah**, [Julia: a fresh approach to numerical computing](https://julialang.org/publications/julia-fresh-approach-BEKS.pdf), SIAM review 2017.
```

The `name` argument, therefore, corresponds to how the bibliography reference will appear in the text.
In the case above, the text will lead to

```plaintext
... refer to (Noether (1915), Bezanson et al. (2017)) while ...
```

You can use either

@@tlist
* `\cite{short1, short2}` or `\citet{short3}`: which will not add parentheses around the link(s),
* `\citep{short4, short5}`: which will add parentheses around the link(s).
@@

As in LaTeX, if the reference is undefined on the page, the command will be replaced by **(??)**.

### Anchor points

You can specify anchor points on the page using `\label{name of the anchor}` anywhere on the page _outside_ of the maths environment.
This will insert an anchor:

```html
<a id="name-of-the-anchor"></a>
```

You can subsequently link to it on the same page:

```plaintext
[link to it](#name-of-the-anchor)
```

or from another page by prepending it with the path to the page, for instance:

```plaintext
[link to it](/index.html#name-of-the-anchor)
```

Note also that all section headers are anchor points for instance

```plaintext
### Some subtitle
```

can be linked to with `#some-subtitle`.
If there are multiple headers with the same name, the second and subsequent ones can be referred to with `#some-subtitle__2`, `#some-subtitle__3` etc. (note the double underscore).
