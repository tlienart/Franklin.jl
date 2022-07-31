<!--
reviewed: 22/12/2019
 -->

@def hascode=true

# Tricks with code evaluation

\blurb{Franklin's recursive nature coupled with code evaluation allows for neat and useful tricks.}

\lineskip

\toc

The basic idea is to exploit the fact that the output of a Julia code block evaluated by Franklin can be re-processed as Franklin Markdown when using the `\textoutput` command; this offers a wide range of possibilities best shown through a few examples (more or less in increasing degree of sophistication).

## Generating a table

### Preview

```julia:table
#hideall
names = (:Taimur, :Catherine, :Maria, :Arvind, :Jose, :Minjie)
numbers = (1525, 5134, 4214, 9019, 8918, 5757)
println("@@simple-table")
println("Name | Number")
println(":--- | :---")
println.("$name | $number" for (name, number) in zip(names, numbers))
println("@@")
raw"""
~~~
<style>
.simple-table tr {
  padding:0;
  line-height:1em;
}
</style>
~~~
""" |> println
```

\textoutput{table}

### Code

That can be obtained with:

`````plaintext
```julia:table
#hideall
names = (:Taimur, :Catherine, :Maria, :Arvind, :Jose, :Minjie)
numbers = (1525, 5134, 4214, 9019, 8918, 5757)
println("Name | Number")
println(":--- | :---")
println.("$name | $number" for (name, number) in zip(names, numbers))
```

\textoutput{table}
`````

The code block will be executed and not shown (`#hideall`) generating a table line by line.
In practice, the code generates the markdown

```markdown
Name | Number
:--- | :---
Bob | 1525
...
Minjie | 5757
```

which is captured and reprocessed by the `\textoutput` command.

This can be used effectively when combined with reading data files etc. and of course you could do further CSS styling of the table.

## Colourful circles

The trick can be used to generate SVG code too.

### Preview

\newcommand{\circle}[1]{~~~<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 4 4"><circle cx="2" cy="2" r="1.5" fill="#1"/></svg>~~~}

```julia:circles
#hideall
colors=(:pink, :lightpink, :hotpink, :deeppink, :mediumvioletred, :palevioletred, :coral, :tomato, :orangered, :darkorange, :orange, :gold, :yellow)
print("@@ccols ")
print.("\\circle{$c}" for c in colors)
println("@@")
```

\textoutput{circles}

### Code

That can be obtained with (see detailed explanations further below)

```html
\newcommand{\circle}[1]{
  ~~~
  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 4 4">
  <circle cx="2" cy="2" r="1.5" fill="#1"/></svg>
  ~~~
}
```

and

`````plaintext
```julia:circles
#hideall
colors=(:pink, :lightpink, :hotpink, :deeppink,
        :mediumvioletred, :palevioletred, :coral,
        :tomato, :orangered, :darkorange, :orange,
        :gold, :yellow)
print("@@ccols ")
print.("\\circle{$c}" for c in colors)
println("@@")
```
\textoutput{circles}
`````


The first part defines a command `\circle` which takes one argument for the fill colour and inserts SVG code for a circle with that colour.

The second part is a Julia code block which will be evaluated but not displayed on the page (since there is a `#hideall`).
The code loops over each colour `c` and prints `\circle{c}` so that the code block effectively generates:

```plaintext
@@ccols \circle{pink}...\circle{yellow}@@
```

this output is then captured and reprocessed with the `\textoutput{snippet}` command.

The last thing to do is to style the `colors` div appropriately:

```css
.ccols {
  margin-top:1.5em;
  margin-bottom:1.5em;
  margin-left:auto;
  margin-right:auto;
  width: 60%;
  text-align: center;}
.ccols svg {
  width:30px;}
```

## Team cards

You may want to have a page with responsive team cards for instance where every card would follow the same layout but the content would be different.
There are multiple ways you can do this with Franklin and a simple one below (adapted from [this tutorial](https://www.w3schools.com/howto/howto_css_team.asp)).
The advantage of doing something like this is that it can help separate the content from the layout making both arguably easier and more maintainable.

### Preview

\newcommand{\card}[5]{
  @@card
    ![#1](/assets/img/team/!#2.jpg)
    @@container
      ~~~
      <h2>#1</h2>
      ~~~
      @@title #3 @@
      @@vitae #4 @@
      @@email #5 @@
      ~~~
      <p><button class="button">Contact</button></p>
      ~~~
    @@
  @@
}

```julia:teamcards
#hideall
team = [
  (name="Jane Doe", pic="beth", title="CEO & Founder", vitae="Phasellus eget enim eu lectus faucibus vestibulum", email="example@example.com"),
  (name="Mike Ross", pic="rick", title="Art Director", vitae="Phasellus eget enim eu lectus faucibus vestibulum", email="example@example.com"),
  (name="John Doe", pic="meseeks", title="Designer", vitae="Phasellus eget enim eu lectus faucibus vestibulum", email="example@example.com")
  ]

"@@cards @@row" |> println
for person in team
  """
  @@column
    \\card{$(person.name)}{$(person.pic)}{$(person.title)}{$(person.vitae)}{$(person.email)}
  @@
  """ |> println
end
println("@@ @@") # end of cards + row

raw"""
~~~
<style>
.column {
  float:left;
  width:30%;
  margin-bottom:16px;
  padding:0 8px;
}
@media (max-width:62rem) {
  .column {
    width:45%;
    display:block;
  }
}
@media (max-width:30rem){
  .column {
    width:95%;
    display:block;
  }
}
.card{
  box-shadow: 0 4px 8px 0 rgba(0,0,0,0.2);
}
.card img {
  padding-left:0;
  width: 100%;
}
.container {
  padding: 0 16px;
}
.container::after, .row::after{
  content:"";
  clear:both;
  display:table;
}
.title {
  color:grey;
}
.vitae {
  margin-top:0.5em;
}
.email {
  font-family:courier;
  margin-top:0.5em;
  margin-bottom:0.5em;
}
.button{
  border:none;
  outline:0;
  display:inline-block;
  padding:8px;
  color:white;
  background-color:#000;
  text-align:center;
  cursor:pointer;
  width:100%;
}
.button:hover{
  background-color:#555;
}
</style>
~~~
""" |> println
```

\textoutput{teamcards}

### Code

In order to do this you could first define a `\card` command:

```html
\newcommand{\card}[5]{
  @@card
    ![#1](/assets/img/team/!#2.jpg)
    @@container
      ~~~
      <h2>#1</h2>
      ~~~
      @@title #3 @@
      @@vitae #4 @@
      @@email #5 @@
      ~~~
      <p><button class="button">Contact</button></p>
      ~~~
    @@
  @@
}
```

And then use it in a loop that goes over each person:

`````plaintext
```julia:teamcards
#hideall
team = [
  (name="Jane Doe", pic="beth", title="CEO & Founder", vitae="Phasellus eget enim eu lectus faucibus vestibulum", email="example@example.com"),
  (name="Mike Ross", pic="rick", title="Art Director", vitae="Phasellus eget enim eu lectus faucibus vestibulum", email="example@example.com"),
  (name="John Doe", pic="meseeks", title="Designer", vitae="Phasellus eget enim eu lectus faucibus vestibulum", email="example@example.com")
  ]

"@@cards @@row" |> println
for person in team
  """
  @@column
    \\card{$(person.name)}{$(person.pic)}{$(person.title)}{$(person.vitae)}{$(person.email)}
  @@
  """ |> println
end
println("@@ @@") # end of cards + row
```

\textoutput{teamcards}
`````

That's about it! though of course a bit of CSS styling is needed such as:

```css
.column {
  float:left;
  width:30%;
  margin-bottom:16px;
  padding:0 8px; }
@media (max-width:62rem) {
  .column {
    width:45%;
    display:block; }
  }
@media (max-width:30rem){
  .column {
    width:95%;
    display:block;}
  }
.card { box-shadow: 0 4px 8px 0 rgba(0,0,0,0.2); }
.card img {
  padding-left:0;
  width: 100%; }
.container { padding: 0 16px; }
.container::after, .row::after{
  content: "";
  clear: both;
  display: table; }
.title { color: grey; }
.vitae { margin-top: 0.5em; }
.email {
  font-family: courier;
  margin-top: 0.5em;
  margin-bottom: 0.5em; }
.button{
  border: none;
  outline: 0;
  display: inline-block;
  padding: 8px;
  color: white;
  background-color: #000;
  text-align: center;
  cursor: pointer;
  width: 100%; }
.button:hover{ background-color: #555; }
```

## Python code blocks

Using [PyCall.jl](https://github.com/JuliaPy/PyCall.jl) you can evaluate Python code in Julia, and so you can do that in Franklin too.
The code below could definitely be improved and generalised but the point here is to show how things can work together.
You could adapt this to work with something like [RCall.jl](https://github.com/JuliaInterop/RCall.jl) as well.

\newcommand{\pycode}[2]{
```julia:!#1
#hideall
using PyCall
lines = replace("""!#2""", r"(^|\n)([^\n]+)\n?$" => s"\1res = \2")
py"""
$$lines
"""
println(py"res")
```
```python
#2
```
\codeoutput{!#1}
}

\pycode{py1}{
import numpy as np
np.random.seed(2)
x = np.random.randn(5)
r = np.linalg.norm(x) / len(x)
np.round(r, 2)
}

### Code

We first define a `\pycode` command that takes lines of python code, adds a `res = ` before the last line, runs the lines and finally show `res`.
It also inputs the lines of code in a fenced block.

`````plaintext
\newcommand{\pycode}[2]{
```julia:!#1
#hideall
using PyCall
lines = replace("""!#2""", r"(^|\n)([^\n]+)\n?$" => s"\1res = \2")
py"""
$$lines
"""
println(py"res")
```
```python
#2
```
\codeoutput{!#1}
}
`````

calling the command is straightforward:

`````
\pycode{py1}{
  import numpy as np
  np.random.seed(2)
  x = np.random.randn(5)
  r = np.linalg.norm(x) / len(x)
  np.round(r, 2)
}
`````
