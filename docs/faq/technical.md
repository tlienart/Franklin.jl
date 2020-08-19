@def hascode=true
@def maxtoclevel=3

# FAQ - Technical

If you have a question that you couldn't find an answer to easily, don't hesitate to [open an issue](https://github.com/tlienart/Franklin.jl/issues/new) on GitHub, it will help me make this section more complete!

\toc

## Styling

### Can you style footnote text?

**Reference**: [issue 243](https://github.com/tlienart/Franklin.jl/issues/243), **more on this**: [styling](/styling/classes/).

For the reference basically a footnote is inserted as

```html
<sup id="fnref:1"><a href="/menu1/#fndef:1" class="fnref">[1]</a></sup>
```

So you can style that with the class `.franklin-content sup a.fnref`.

For definitions, it's inserted as a table like:

```html
<table class="fndef" id="fndef:blah">
    <tr>
        <td class="fndef-backref"><a href="/menu1/#fnref:blah">[2]</a></td>
        <td class="fndef-content">this is another footnote</td>
    </tr>
</table>
```

so you can style the back-reference via the `.franklin-content fndef td.fndef-backref` and the text of the definition via `.franklin-content fndef td.fndef-content`; for instance, consider the following base styling:

```css
.franklin-content table.fndef  {
    margin: 0;
    margin-bottom: 10px;}
.franklin-content .fndef tr, td {
    padding: 0;
    border: 0;
    text-align: left;}
.franklin-content .fndef tr {
    border-left: 2px solid lightgray;
    }
.franklin-content .fndef td.fndef-backref {
    vertical-align: top;
    font-size: 70%;
    padding-left: 5px;}
.franklin-content .fndef td.fndef-content {
    font-size: 80%;
    padding-left: 10px;}
```

### How to disable numbering of math in display mode?

It is possible to specify in the CSS which Katex equations will be numbered or not by adjusting the
`.katex-display::after` class.
If you want to disable numbering in the entire site, just head to `_css/franklin.css` and remove the `.katex-display::after` block.
You can also build a simple way to disable all numbering inside a specified `@@` div 
(see [div blocks](/syntax/divs-commands/#div_blocks))

```markdown
This is numbered:
$$ 1+1 = 2 $$

This isn't:

@@no-number
$$ 2+2 = 4 $$
and
$$ 3+3 = 7-1 $$
@@

Numbered again:
$$ 7 + 1 = 8 $$
```

by adding in the CSS:
```css
.no-number .katex-display::after {
  counter-increment: nothing;
  content: "";
}
```

And possibly [define a command](/syntax/divs-commands/#latex-like_commands) in `config.md`:\
```markdown
\newcommand{\nalign}[1]{@@no-number \begin{align}#1\end{align}@@}
```
if you feel it is more convenient to write `\nalign{3+3 = 6}`.


## Code

### How to use loops for templating?

**Reference**: [issue 251](https://github.com/tlienart/Franklin.jl/issues/251), **more on this**: [code tricks](/code/eval-tricks/).

Since you can show the output of any Julia code block (and interpret that output as Franklin markdown), you can use this to help with templating.
For instance:

`````md
```julia:./ex
#hideall
for name in ("Shinzo", "Donald", "Angela", "Christine")
    println("""
    @@card
    ### $name
    ![]("$(lowercase(name)).jpg")
    @@
    """)
end
```
\textoutput{./ex}
`````

Generates

```html
<div class="card"><h3 id="shinzo"><a href="/index.html#shinzo">Shinzo</a></h3>  <img src="shinzo.jpg" alt="" /></div>
<div class="card"><h3 id="donald"><a href="/index.html#donald">Donald</a></h3>  <img src="donald.jpg" alt="" /></div>
<div class="card"><h3 id="angela"><a href="/index.html#angela">Angela</a></h3>  <img src="angela.jpg" alt="" /></div>
<div class="card"><h3 id="christine"><a href="/index.html#christine">Christine</a></h3>  <img src="christine.jpg" alt="" /></div>
```

### How to insert Plotly plots?

**Reference**: [issue 322](https://github.com/tlienart/Franklin.jl/issues/322).

See [this tutorial](/extras/plotly/) for a way to do this.
