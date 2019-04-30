# Templating

This page is about the templating syntax that is used in JuDoc which allows you to have some control over the generated HTML.
It can be useful as a way to, depending on the page,

* adjust the layout,
* specify elements that should be inserted in the page such as date of last modification, page author(s), etc.,
* specify auxiliary elements that should be loaded with the page such as stylesheets or javascript libraries,
* ...

!!! note

    The templating system is still rudimentary at this point and is likely to be significantly improved over time (your help and suggestions are welcome!).

**Contents**:

* [Basic syntax](#Basic-syntax-1)
* [Conditional blocks](#Conditional-blocks-1)
  * [Base conditional blocks](#Base-conditional-blocks-1)
  * [`isdef` conditional blocks](#isdef-conditional-blocks-1)
  * [`ispage` conditional blocks](#ispage-conditional-blocks-1)
* [Function blocks](#Function-blocks-1)

## Basic syntax

When developing your website, you can define global or local page variables using

```judoc
@def varname = ...
```

either in the `src/config.md` file  (in which case the variable is global) or in a specific page (in which case the variable is local or overwrites a global one).
See also the page on the markdown [Syntax](@ref).

These variables can subsequently be called in "HTML Blocks" in a way that is inspired from Hugo's templating system via `{{...}}`.
These blocks would be placed in the  HTML layout building blocks files that are in `src/_html_parts/`.

A simple example is the insertion of a string defining the title of the page (which would appear the tab name).
In the markdown of `src/path/page1.md` you would have:

```judoc
@def title = "Title for page 1"
```

and in `src/_html_parts/head.html` you would have

```html
<title>{{fill title}}</title>
```

This HTML block has the form `{{function_name a b ...}}` where `a`, `b`, ... are page variable names.
Here the `fill` function simply tries to find a page variable `"title"` and places its content here so that in the final generated HTML, there would be:

```html
<title>Title for page 1</title>
```

See [Function blocks](#Function-blocks-1) for more such functions that can be used.

!!! note

    Whitespaces in HTML blocks are irrelevant as long as the different parts are separated by at least one so for instance `{{fill title }}` or `{{ fill   title}}` would both be fine.

## Conditional blocks

It will often be handy to do things in your layout conditional on specific variables.
Three types of conditional blocks are allowed:

* a "classical" conditional block with `if`, `elseif`, `else` that accepts page variables that have boolean value,
* a conditional block that does something provided a variable exists (or not),
* a conditional block that does something depending on whether the page is a specific one (or not a specific one).

!!! note

    Nesting of conditional blocks is currently **not allowed**  but shouldn't be hard to implement and will likely be supported in the near future.

### Base conditional blocks

Such blocks have the structure

```html
{{if vname1}}
...
{{elseif vname2}}
...
{{else}}
...
{{end}}
```

where the `{{elseif ... }}` and `{{else}}` blocks are optional.
They work as you would expect: look up the variables `vname1` in the currently available page variables, if it doesn't exist an error will be shown and the whole conditional block will be ignored, otherwise the value is retrieved and depending on whether it is `true` or `false` the relevant blocks will be executed.

As a simple example consider a variable `draft` which you could use to control the addition of a banner at the top of a page indicating it's still work in progress:

in `src/pages/pg1.md` you would have

```julia
@def draft = true
```

while in `src/_html_parts/head.html` you could have

```html
{{if draft}}
<div class="draft-banner" style="background-color:red;
color:white;padding:10px;font-weight:bold;">
    This is currently work in progress!
</div>
{{end}}
```

### `isdef` conditional blocks

The `{{isdef vname}}` or `{{isnotdef vname}}` are blocks that do something depending on whether a specific variable exists (or not):

```html
{{isdef author}}
...
{{end}}
```

Such blocks can be useful where you sometimes want something to be defined and sometimes not.

For instance, you may want to add a title if the variable `title` exists: in the markdown you would then either have `@def title = ...` or not and in the `head.html`:

```html
{{isdef title}}
<title>{{fill title}}</title>
{{end}}
```

!!! note

    Currently these blocks do not accept `{{else}}` statements but this should be supported in the near future.

### `ispage` conditional blocks

The `{{ispage path/to/page}}` or `{{isnotpage path/to/page}}` are blocks that do something depending on whether the page is a specific one (or not).
For instance in the `pure-sm` template, in the `head.html` you will see elements for the side menu with

```html
<li class="pure-menu-item {{ispage /index.html}}pure-menu-selected{{end}}">
    <a href="/" class="pure-menu-link">Home</a>
</li>
```

which add a class to a `<li>` object depending on the page that indicate which list item should be styled as a "selected" button depending on the page we're on.

!!! note

    As the def blocks above, these blocks do not yet accept `{{else}}` statements.

## Function blocks

These are blocks of the form

```html
{{f_name p1 p2}}
```

where `f_name` is a function name (see below) and `p1`, `p2` would be variable names that correspond to arguments of the function.

| Name | #params | Example | Role |
| :------------ | :------------------- | :------ | :--- |
| `fill` | 1 | `{{fill author}}` | replaces the block with the value of the page variable
| `insert` | 1 | `{{insert path/to/file}}` | replaces the block with the content of the file at `path/to/file`

!!! note

    If you would like to have more of those, please open an issue and explain the use-case, I'll be happy to expand the list.
