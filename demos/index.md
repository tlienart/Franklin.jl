@def title = "Franklin FAQ"

# Franklin Demos

\style{text-align:center;width:100%;display:inline-block;font-variant-caps:small-caps}{[**Click here to see the source**](https://github.com/tlienart/Franklin.jl/tree/master/demos)}

This website is meant to be a quick way to show how to do stuff that people ask (or that I thought would be a nice demo), it will complement the [official documentation](https://franklinjl.org/).

It's not meant to be beautiful, rather just show how to get specific stuff done.
If one block answers one of your question, make sure to check [the source](https://github.com/tlienart/FranklinFAQ/blob/master/index.md) to see how it was done.
The ordering is reverse chronological but just use the table of contents to guide you to whatever you might want to explore.

**Note**: an important philosophy here is that if you can write a Julia function that would produce the HTML you want, then write that function and let Franklin call it.

\toc

## (006) code highlighting

Inserting highlighted code is very easy in Franklin; just use triple backquotes and the name of the language:

```julia
struct Point{T}
  x::T
  y::T
end
```

The highlighting is done via highlight.js, it's important to understand there are two modes:

* using the `_libs/highlight/highlight.pack.js`, this happens when serving locally **and** when publishing a website **without** pre-rendering,
* using the full `highlight.js` package, this happens when pre-rendering and supports all languages.

The first one only has support for selected languages (by default: `css`, `C/AL`, `C++`, `yaml`, `bash`, `ini`, `TOML`, `markdown`, `html`, `xml`, `r`, `julia`, `julia-repl`, `plaintext`, `python` with the minified `github` theme), you can change this by going to the [highlightjs](https://highlightjs.org/download/) and making your selection.

The recommendation is to:

- check whether the language of your choosing is in the default list above (so that when you serve locally things look nice), if not, go to the highlight.js website, get the files, and replace what's in `_libs/highlight/`,
- use pre-rendering if you can upon deployment.

Here are some more examples with languages that are in the default list:

```r
# some R
a <- 10
while (a > 4) {
  cat(a, "...", sep = "")
  a <- a - 1
}
```

```python
# some Python
def foo():
  print("Hello world!")
  return
```

```cpp
// some c++
#include <iostream>

int main() {
  std::cout << "Hello World!";
  return 0;
}
```

```css
/* some CSS */
p {
  border-style: solid;
  border-right-color: #ff0000;
}
```

## (005) pagination

Pagination works with `{{paginate list num}}` where `list` is a page variable with elements that you want to paginate (either a list or tuple), and `num` is the number of elements you want per page.
There are many ways you can use this, one possible way is to wrap it in a command if you want to insert this in an actual list which is what is demoed here:

\newcommand{\pglist}[2]{~~~<ul>~~~{{paginate #1 #2}}~~~</ul>~~~}

@def alist = ["<li>item $i</li>" for i in 1:10]

\label{pgex}
\pglist{alist}{4}

Now observe that

* [page 1](/1/#pgex) has items 1-4
* [page 2](/2/#pgex) has items 5-8
* [page 3](/3/#pgex) has items 9-10

## (004) use Latexify.jl

Latexify produces a LaTeX string which should basically be passed to KaTeX. To do that you need to recuperate the output, extract the string and pass it into a maths block.

Here there's a bug with `\begin{equation}` in Franklin (issue [#584](https://github.com/tlienart/Franklin.jl/issues/584)) which is why I'm replacing those with `$$` but it should be fixed in the near future so that you wouldn't have to use these two "replace" lines:

```julia:lx1
using Latexify
empty_ary = Array{Float32, 2}(undef, 2, 2)
ls = latexify(empty_ary) # this is an L string
println(ls.s) # hide
```

\textoutput{lx1}

## (003) styling of code output blocks

At the moment (August 2020) no particular class is added on an output (see [#531](https://github.com/tlienart/Franklin.jl/issues/531)); you can still do something similar by adding a `@@code-output` (or whatever appropriate name) around the command that extracts the output and specify this in your css (see `extras.css`):

```julia:cos1
x = 7
```

@@code-output
\show{cos1}
@@

If you find yourself writing that a lot, you should probably define a command like

```plaintext
\newcommand{\prettyshow}[1]{@@code-output \show{#1} @@}
```

and put it in your `config.md` file so that it's globally available.

\prettyshow{cos1}

## (002) code block scope

On a single page all code blocks share their environment so

```julia:cbs1
x = 5
```

then

```julia:cbs2
y = x+2
```

\show{cbs2}

## (001) how to load data from file and loop over rows

This was asked on Slack with the hope it could mimick the [Data Files](https://jekyllrb.com/docs/datafiles/) functionality of Jekyll where you would have a file like

```
name,github
Eric Mill,konklone
Parker Moore,parkr
Liu Fengyun,liufengyun
```

and you'd want to loop over that and do something with it.

**Relevant pieces**:
* see `_assets/members.csv` (content is the code block above)

### Approach 1, with a `hfun`

* see `utils.jl` for the definition of `hfun_members_table`; calling `{{members_table _assets/members.csv}}` gives

{{members_table _assets/members.csv}}


### Approach 2, with a page variable and a for loop

* see `config.md` for the definition of the `members_from_csv` _global_ page variable.

Writing the following

```html
~~~
<ul>
{{for (name, alias) in members_from_csv}}
  <li>
    <a href="https://github.com/{{alias}}">{{name}}</a>
  </li>
{{end}}
</ul>
~~~
```

gives:

~~~
<ul>
{{for (name, alias) in members_from_csv}}
  <li>
    <a href="https://github.com/{{alias}}">{{name}}</a>
  </li>
{{end}}
</ul>
~~~

**Notes**:
* we use a _global_ page variable so that we don't reload the CSV file every single time something changes on the caller page.
