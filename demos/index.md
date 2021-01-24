@def title = "Franklin FAQ"
@def tags = ["index"]

# Franklin Demos

\style{text-align:center;width:100%;display:inline-block;font-variant-caps:small-caps}{[**Click here to see the source**](https://github.com/tlienart/Franklin.jl/tree/master/demos)}

This website is meant to be a quick way to show how to do stuff that people ask (or that I thought would be a nice demo), it will complement the [official documentation](https://franklinjl.org/).

It's not meant to be beautiful, rather just show how to get specific stuff done.
If one block answers one of your question, make sure to check [the source](https://github.com/tlienart/Franklin.jl/tree/master/demos/index.md) to see how it was done.
The ordering is reverse chronological but just use the table of contents to guide you to whatever you might want to explore.

**Note**: an important philosophy here is that if you can write a Julia function that would produce the HTML you want, then write that function and let Franklin call it.

**Note 2**: the numbering in georgian script in the table of content is on purpose (though for no particularly good reason other than that it looks nice... 🇬🇪)

\toc

## (013) Inserting Markdown in Markdown

Let's say you have a file `content.md` and you would like to include it in another page as if it had been written there in the first place.
This is pretty easy to do.
You could for instance use the following function:

```julia
function hfun_insertmd(params)
  rpath = params[1]
  fullpath = joinpath(Franklin.path(:folder), rpath)
  isfile(fullpath) || return ""
  return read(fullpath, String)
end
```

One thing to note is that all `.md` files in your folder will be considered as potential pages to turn into HTML, so if a `.md` file is meant to exclusively be used "inserted", you should remove it from Franklin's reach by adding it to the `ignore` global variable putting something like this in your `config.md`:

```
@def ignore = ["path/to/content.md"]
```

Here's an example with the insertion of the content of a file `foo/content.md`; the result of `{{insertmd foo/content.md}}` is:

{{insertmd foo/content.md}}

You can look at [`utils.jl`](https://github.com/tlienart/Franklin.jl/blob/master/demos/utils.jl) for the definition of the `hfun` (same as above), at [`index.md`](https://github.com/tlienart/Franklin.jl/blob/master/demos/index.md) to see how it's called and at [`foo/content.md`](https://github.com/tlienart/Franklin.jl/blob/master/demos/foo/content.md) for the content file.

## (012) Dates

The date of last modification on the page is kept in the `fd_mtime_raw` internal page variable, there is also a pre-formatted `fd_mtime`.

Last modified: {{fd_mtime_raw}} or {{fd_mtime}}

## (011) showing type information

This is a short demo following a discussion on Slack, it shows three things:

* how to mark a block as "_run here directly and show the output_" without having to explicitly add a path and use a `\show`
* that types are now shown properly as they would be in the REPL.
* that continuation works from cell to cell (i.e. you can assume that a cell further below another cell has access to what was defined in the first)

```!
s = "hello"
struct T; v::Int; end
[
    Dict(:a => T(1)),
    Dict(:b => T(2)),
]
```

Here's another cell

```!
T(1)
print(s)
```

Suppressed output:

```!
X = randn(2, 3);
```


## (010) clipboard button for code blocks

It's fairly easy to add a "copy" button to your code blocks using  a tool like [`clipboard.js`](https://clipboardjs.com).
In fact on this demo page, as you can see, there is a copy button on all code blocks.
The steps to  reproduce  this are:

* copy the [`clipboard.min.js`](https://github.com/tlienart/Franklin.jl/blob/master/demos/_libs/clipboard.min.js) to `/libs/clipboard.min.js` (_note that this is an old version of the library, `1.4` or something, if you take  the most recent version, you will have to adapt the script_)
* load that in `_layout/head.html` adding something like

```html
<script src="/libs/clipboard.min.js"></script>
```

* add Javascript in the `_layout/foot.html`,  something [like this](https://github.com/tlienart/Franklin.jl/blob/master/demos/_layout/foot_clipboard.html)
* adjust the CSS, for instance [something like this](https://github.com/tlienart/Franklin.jl/blob/0276b1afb054017ff7e81bc7d083021a867a4b92/demos/_css/extras.css#L37-L61)

and that's it 🏁.

## (009) custom environment for TikzCD

Following up on [#008](#008_custom_environments_and_commands), here's a custom environment for Tikz diagrams using the [TikzCDs.jl](https://github.com/JuliaTeX/TikzCDs.jl) package.

Let's first see what you get for your effort:

@@small-imgc \begin{tikzcd}{tcd1}
A \arrow[r, "\phi"] \arrow[d, red]
  & B \arrow[d, "\psi" red] \\
  C \arrow[r, red, "\eta" blue]
  & D
\end{tikzcd}@@

Cool! Modulo a div class that shrinks the image a bit, the code that was used here is very nearly a copy-paste from an example in the [tikz-cd docs](https://ctan.kako-dev.de/graphics/pgf/contrib/tikz-cd/tikz-cd-doc.pdf), the only difference is one additional bracket with the file name (here `tcd1`):

```plaintext
\begin{tikzcd}{tcd1}
A \arrow[r, "\phi"] \arrow[d, red]
  & B \arrow[d, "\psi" red] \\
  C \arrow[r, red, "\eta" blue]
  & D
\end{tikzcd}
```

The corresponding `env_tikzcd` function is in the `utils.jl` file and is quite simple.

**Note**: in this particular case, the environment uses the [`TikzCDs.jl`](https://github.com/JuliaTeX/TikzCDs.jl) which requires having `lualatex` and `dvisgm` as per their README.
For this to work with a GitHub action, the relevant stuff needs to be installed, it's not hard to do so with GitHub actions though you need to get TeXLive 2019 to avoid errors, I used [these 3 lines](https://github.com/tlienart/Franklin.jl/blob/354ac015c14aaedf9ebeaeb9d0b574ddad3738e5/.github/workflows/deploy.yml#L20-L23) which you could copy.

## (008) (custom) environments and commands

You can define new commands and new environments using essentially the same syntax as in LaTeX:

```plaintext
\newcommand{\command}[nargs]{def}
\newenvironment{environment}[nargs]{pre}{post}
```

The first one allows to define a command that you can call as `\command{...}` and the second one an environment that you can call as
```plaintext
\begin{environment}{...}...\end{environment}
```
In both cases you can have a number of arguments (or zero) and the output is _reprocessed by Franklin_ (so treated as Franklin-markdown).
Here are a few simple examples:

```plaintext
\newcommand{\hello}{**Hello!**}
Result: \hello.
```
\newcommand{\hello}{**Hello!**}
Result: \hello.

```plaintext
\newcommand{\html}[1]{~~~#1~~~}
\newcommand{\red}[1]{\html{<span style="color:red">#1</span>}}
Result: \red{hello!}.
```
\newcommand{\html}[1]{~~~#1~~~}
\newcommand{\red}[1]{~~~<span style="color:red">#1</span>~~~}
Result: \red{hello!}.

```plaintext
\newenvironment{center}{
  \html{<div style="text-align:center">}
}{
  \html{</div>}
}
Result: \begin{center}This bit of text is in a centered div.\end{center}
```
\newenvironment{center}{
  \html{<div style="text-align:center">}
}{
  \html{</div>}
}
Result: \begin{center}This bit of text is centered.\end{center}

```plaintext
\newenvironment{figure}[1]{
  \html{<figure>}
}{
  \html{<figcaption>#1</figcaption></figure>}
}
Result: \begin{figure}{A koala eating a leaf.}![](/assets/koala.jpg)\end{figure}
```
\newenvironment{figure}[1]{
  \html{<figure>}
}{
  \html{<figcaption>#1</figcaption></figure>}
}
Result: \begin{figure}{A koala eating a leaf.}![](/assets/koala.jpg)\end{figure}

### Customise with Julia code

Much like `hfun_*`, you can have commands and environments be effectively defined via Julia code. The main difference is that the output will be treated as Franklin-markdown and so will be _reprocessed by Franklin_ (where for a `hfun`, the output is plugged in directly as HTML).

In both cases, a single option bracket is expected, no more no less. It can be empty but it has to be there. See also [the docs](https://franklinjl.org/syntax/utils/#latex_functions_lx_) for more information.

Here are two simple examples (see in `utils.jl` too):

```julia
function lx_capa(com, _)
  # this first line extracts the content of the brace
  content = Franklin.content(com.braces[1])
  output = replace(content, "a" => "A")
  return "**$output**"
end
```

```plaintext
Result: \capa{Baba Yaga}.
```
Result: \capa{Baba Yaga}.

```julia
function env_cap(com, _)
  option = Franklin.content(com.braces[1])
  content = Franklin.content(com)
  output = replace(content, option => uppercase(option))
  return "~~~<b>~~~$output~~~</b>~~~"
end
```

```plaintext
Result: \begin{cap}{ba}Baba Yaga with a baseball bat\end{cap}
```
Result: \begin{cap}{ba}Baba Yaga with a baseball bat\end{cap}

Of course these are toy examples and you could have arrived to the same effect some other way.
With a bit of practice, you might develop a preference towards using one out of the three options:  `hfun_*`, `lx_*` or `env_*` depending on your context.

## (007) delayed hfun

When you call `serve()`, Franklin first does a full pass which builds all your pages and then waits for changes to happen in a given page before updating that page.
If you have a page `A` and a page `B` and that the page `A` calls a function which would need something that will only be defined once `B` is built, you have two cases:

1. A common one is to have the function used by `A` require a _local_ page variable defined on `B`; in that case just use `pagevar(...)`. When called, it will itself build `B` so that it can access the page variable defined on `B`. This is usually all you need.
1. A less common one is to have the function used by `A` require a _global_ page variable such as, for instance, the list of all tags, which is only complete _once all pages have been built_. In that case the function to be used by `A` should be marked with `@delay hfun_...(...)` so that Franklin knows it has to wait for the full pass to be completed before re-building `A` now being sure that it will have access to the proper scope.

The page [foo](/foo/) has a tag `foo` and a page variable `var`; let's show both use cases; see `utils.jl` to see the definition of the relevant functions.

**Case 1** (local page variable access, `var = 5` on page foo): {{case_1}}

**Case 2** (wait for full build, there's a tag `index` here and a tag `foo` on page foo): {{case_2}}

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
