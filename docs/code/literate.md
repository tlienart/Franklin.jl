@def hascode = true
@def showall = true
@def hasmath = true

# Work with Literate.jl

\blurb{Franklin works seamlessly with Literate to offer a convenient way to write and maintain tutorials.}

\lineskip

\toc

## Overview

[Literate.jl](https://github.com/fredrikekre/Literate.jl) is a convenient package that allows you to write scripts in Julia and convert them to markdown pages or Jupyter notebooks.

You can combine this with Franklin with the `\literate` command which you can call in Franklin like:

```
\literate{/_literate/script.jl}
```

it does what you expect:

@@tlist
* the markdown is interpreted and evaluated
* the code blocks are evaluated and their output can be shown selectively
@@

If you want the script to be shown like a notebook where the output of every code block is shown, use  `@def showall = true`.

Combining Franklin with Literate offers a very convenient way to write and maintain tutorial websites (see for instance the [DataScienceTutorials](https://github.com/alan-turing-institute/DataScienceTutorials.jl)).

### File organisation

We recommend you have a folder `/_literate/` in your root folder, place your literate scripts there and call them as in the example above.

### Tricks

In the `showall = true` mode, the last line of each code block is displayed in full.
In some cases you will have to  think about this a bit more than you would in your REPL and might for instance:

@@tlist
* _suppress the output_, in which case  you should add a `;`  at the end  of the line
* _only show a few elements_ (see below)
@@

For instance you might prefer:

```julia:ee0
x = randn(10)
x[1:3]
```

to just

```julia:ee1
x = randn(10)
```

You can also use `@show` or `println` to show specific things beyond the last line

```julia:ee2
x = rand(10)
println(sum(x))
y = 5
```

if the last line is a `@show` or `print` then only that is shown:

```julia:ee3
x = randn(10)
@show x[1]
```

## Example

### Script

`````julia
# Some **really cool** maths:
#
# $$ \exp(i\pi) + 1 \quad = \quad 0 $$
#
# We can show this with some code:

x = exp(im*π) + 1

# that looks close to zero but

x ≈ 0

# however

abs(x) < eps()

# #### Conclusion
#
# The equation is proven thanks to our very rigorous proof.
`````

### Result

\literate{/_literate/script_ee.jl} <!--_-->
