# Design

This page aims to shed some light on how JuDoc works and how the code is structured which could be of interest for anyone willing to contribute to the codebase.

## Big Picture

### Compilation

The overarching sequence for the initial _full pass_ is:

1. retrieve the paths to files that should be processed ([`JuDoc.jd_setup`](@ref)),
1. process all files ([`JuDoc.jd_fullpass`](@ref))
   * if it's a markdown file convert it to HTML (see below),
   * place generated file in appropriate locations.

In general the user will use `serve()` which triggers a full pass followed by a loop that re-processes files individually upon modifications ([`JuDoc.jd_loop`](@ref)).

### File processing

The file processing is controlled by the function [`JuDoc.process_file`](@ref) which, itself, is a thin wrapper around the function [`JuDoc.process_file_err`](@ref) (the first one processes any errors that may be generated during the processing of files).
There are three types of files:

* markdown files (`.md`) which are parsed and converted into HTML,
* HTML files (`.html`) which are parsed and re-generated after solving any templating commands they may contain,
* other files which are just copied over to the relevant location.

In the case of markdown files, the function [`JuDoc.write_page`](@ref) is called and is formed of 3 key stages:

1. parsing of the markdown ([`JuDoc.convert_md`](@ref))
1. conversion to HTML and assembly of different blocks into one page ([`JuDoc.convert_html`](@ref) and [`JuDoc.build_page`](@ref)),
1. writing the HTML in the appropriate location, possibly after pre-rendering javascript ([`JuDoc.js_prerender_katex`](@ref), [`JuDoc.js_prerender_highlight`](@ref)).


## Parsing

!!! note

    If you wonder why I didn't just use a "standard parser", one of my personal goal was to try to build a parser from scratch to get an idea of how one would work. I don't doubt better can be done though I doubt it's a serious bottleneck at the moment.

At the very basic level, the parser reads the content from left to right and tries to find "blocks" that should be processed in a specific way.
Once blocks have been found, each block gets processed in turn following the appropriate order in which they appear.
Finally, they are re-assembled after processing.

The overarching block type is the [`JuDoc.AbstractBlock`](@ref) with as key sub-types `Token` and `OCBlock`:

* [`JuDoc.Token`](@ref): these correspond to the idea of a _specific sequence of characters_ which typically will denote the _start_ or the _end_ of an environment. The type contains a substring corresponding to the matched token and a name indicating what the token is.

```julia-repl
julia> s = raw"Hello, $x=5$ end";
julia> t = JuDoc.find_tokens(s, JuDoc.MD_TOKENS, JuDoc.MD_1C_TOKENS)
2-element Array{JuDoc.Token,1}:
 JuDoc.Token(:MATH_A, "\$")
 JuDoc.Token(:MATH_A, "\$")

julia> JuDoc.from(t[1])
8
julia> JuDoc.from(t[1])
12
```

* [`JuDoc.OCBlock`](@ref): these correspond to the idea of an _environment_ delimited by an opening and a closing token. The type contains a substring corresponding to the full block, a name indicating what the environment is and a pair of opening and closing tokens (whence the name "O/C").

```julia-repl
julia> ocb, _ = JuDoc.find_all_ocblocks(t, JuDoc.MD_OCB_ALL);
julia> ocb
1-element Array{JuDoc.OCBlock,1}:
 JuDoc.OCBlock(:MATH_A, JuDoc.Token(:MATH_A, "\$") => JuDoc.Token(:MATH_A, "\$"), "\$x=5\$", false)

julia> JuDoc.from(ocb[1])
8

julia> JuDoc.to(ocb[2])
12
```

### Finding Tokens

The function [`JuDoc.find_tokens`](@ref) takes content, reads it from left to right and returns a list of `Token`s.
It takes a string, and two "token dictionaries".
The first one describes tokens that span _multiple characters_ while the second one correspond to tokens that span _a single character_.

Single character tokens are tokens that are exclusively defined by a single character.
These characters **cannot** be part of multi-chars tokens.
For instance, [`JuDoc.MD_1C_TOKENS`](@ref) corresponds to single-char tokens in markdown with entries such as:

```julia
'{'  => :LXB_OPEN,
```

The key of these entries is a `Char` and as soon as the function sees that character while it reads the content, a Token is formed with the corresponding name (here `:LXB_OPEN` which stands for _latex-brace-open_).

As for multi-char tokens, for instance, [`JuDoc.MD_TOKENS`](@ref), entries look like:

```julia
'<' => [ isexactly("<!--") => :COMMENT_OPEN ],
```

The key of these entries is also of type `Char` (the first character of such a token) followed by a vector of [`JuDoc.TokenFinder`](@ref) which essentially is a pair where the first value indicates how to match the token and the second one what name to associate to it if there is a match.
Since multiple tokens can start with the same character, there is a vector of "rules".
Note that order in the vector matters: the first match wins.

In the case above, if the function sees a `<` character while reading the content, it will look ahead and try to match exactly `<!--`.
If there is a match, then a Token is formed with name `:COMMENT_OPEN`.

Another look-ahead rule is `incrlook` which matches a variable number of characters that respect a given condition.
For instance, let's consider markdown tokens that start with `@`:

```julia
'@' => [
     isexactly("@def", [' '])  => :MD_DEF_OPEN,
     isexactly("@@", SPACER)   => :DIV_CLOSE,
     incrlook((i, c) -> ifelse(i==1, c=='@', α(c, ['-']))) => :DIV_OPEN ],
```

The vector of `TokenFinder` contains three rules:

1. try to match exactly `@def` followed by a space in which case a `:MD_DEF_OPEN` token is created,
1. try to match exactly `@@` followed by any space character (e.g. a space or a line return) in which case a `:DIV_CLOSE` token is created,
1. try to match `@@` followed by a number of letters or dashes.

For the last case, note the function `(i, c) -> ifelse(...)` which takes a character index `i` and a character `c` starting at the first character after the initial matching character (here the initial matching character is an `@` so the first character after that is also an `@`).
So the function checks that the first character after the matching `@` is also an `@` and subsequently accepts any character that is either a letter or a `-`.

```julia-repl
julia> s = raw"Hello @@d-name ... @@ etc";
julia> JuDoc.find_tokens(s, JuDoc.MD_TOKENS, JuDoc.MD_1C_TOKENS)
2-element Array{JuDoc.Token,1}:
 JuDoc.Token(:DIV_OPEN, "@@d-name")
 JuDoc.Token(:DIV_CLOSE, "@@")

```

### Finding OCBlocks

`OCBlocks` are simply defined by a name, an opening and a closing token and an indicator of whether there may be nested blocks or not.
The function [`JuDoc.find_all_ocblocks`](@ref) takes a list of tokens and tries to match them corresponding to pre-defined rules.

For instance, consider `JD.MD_OCB` which describes non-math ocblocks in markdown; it contains entries like:

```julia
:COMMENT => ((:COMMENT_OPEN => :COMMENT_CLOSE), false),
```

indicating that a `:COMMENT` ocblock starts at a `:COMMENT_OPEN` token (a `<!--`) and ends at the next `:COMMENT_CLOSE` (a `-->`) with no nesting.

When nesting is allowed (for instance div blocks can be nested) then the function `find_all_ocblocks` keeps track of the number of opening and closing tokens and returns the outer-most block (which will be decomposed further at a later stage).

```julia-repl
julia> s = raw"Hello @@d-name-a ... @@d-name-b @@ ... @@ etc";
julia> t = JuDoc.find_tokens(s, JuDoc.MD_TOKENS, JuDoc.MD_1C_TOKENS);
julia> ocb, _ = JuDoc.find_all_ocblocks(t, JuDoc.MD_OCB);
julia> length(ocb)
1

julia> ocb[1].name
:DIV

julia> ocb[1].ss
"@@d-name-a ... @@d-name-b @@ ... @@"

```

When a token has been snapped up in a ocblock, it is marked as inactive so that it doesn't get re-processed.

### LaTeX blocks

When parsing a markdown file, after finding tokens and ocblocks, JuDoc tries to find [`JuDoc.LxDef`](@ref) and [`JuDoc.LxCom`](@ref) blocks (also `AbstractBlock`).

The first one corresponds to LaTeX _definitions_ of the form `\newcommand{\name}[narg]{def}` while the second one corresponds to LaTeX _commands_ such as `\foo` or `\foo{bar}` or `\foo{bar}{baz}` etc.

The function [`JuDoc.find_md_lxdefs`](@ref) takes a vector of active tokens and a ocblocks and finds sequences that match the format of a newcommand.
Its counterpart, [`JuDoc.find_md_lxcoms`](@ref) takes a vector of active tokens and definitions and ocblocks and finds sequences that match the format of a command.

```julia-repl
julia> s = raw"a \newcommand{\foo}[1]{_blah #1_} and \foo{hello} done.";
julia> t = JuDoc.find_tokens(s, JuDoc.MD_TOKENS, JuDoc.MD_1C_TOKENS);
julia> ocb, t = JuDoc.find_all_ocblocks(t, JuDoc.MD_OCB);
julia> lxd, t, braces, blocks = JuDoc.find_md_lxdefs(t, ocb);
julia> lxd[1]
JuDoc.LxDef("\\foo", 1, "_blah #1_", 3, 33)

julia> lxc, t = JuDoc.find_md_lxcoms(t, lxd, braces);
julia> lxc[1]
JuDoc.LxCom(
   "\\foo{hello}",
   Base.RefArray{...}(...),
   JuDoc.OCBlock[JuDoc.OCBlock(:LXB, JuDoc.Token(:LXB_OPEN, "{") => JuDoc.Token(:LXB_CLOSE, "}"),
   "{hello}", true)])

```

In the `LxCom`, the output was truncated for readability, the second field is a reference to the appropriate LaTeX definition of the command while the final field is a vector formed of ocblocks which correspond to each of the arguments (here only a single one: `{hello}`).

### HTML blocks

When parsing a HTML file, JuDoc also tries first to find tokens (see [`JuDoc.HTML_TOKENS`](@ref)) and ocblocks (see [`JuDoc.HTML_OCB`](@ref)).
In particular, it will find ocblocks of the form `{{ ... }}` ("HTML blocks").
Subsequently, JuDoc will try to _qualify_ those HTML blocks and form a specific block such as a `HIf` or a `HElse` block (see [`JuDoc.qualify_html_hblocks`](@ref)):

| Form  | Name  |
| :--- | :--- |
| `{{if var}}` | `HIf` |
| `{{elseif var}}` | `HElseIf` |
| `{{else}}` | `HElse` |
| `{{end}}`| `HEnd` |
| `{{is[not]def var}}` | `HIs[Not]Def` |
| `{{is[not]page path}}`| `HIs[Not]Page` |

These blocks can then be assembled in larger blocks such as `HCond` (corresponding to an if-elseif-else-end), see [`JuDoc.find_html_cblocks`](@ref), [`JuDoc.JuDoc.find_html_cdblocks`](@ref) and [`JuDoc.JuDoc.find_html_cpblocks`](@ref).

## Conversion

### Markdown conversion

The core function corresponding to the conversion of a markdown document is, as mentioned before, [`JuDoc.convert_md`](@ref).
The first part corresponds to the parsing discussed above to find:

1. tokens
1. open/close blocks
1. LaTeX-like definitions
1. LaTeX-like commands
1. Markdown definitions (e.g. `@def x = 5`)

This parsing step creates a number of _blocks_ which each have to be processed in turn.
The function [`JuDoc.form_inter_md`](@ref) takes the vector of all blocks and latex definitions and forms an intermediate markdown where places where an insertion must occur are marked with `##JDINSERT##`.
This intermediate markdown is then fed to the function [`JuDoc.md2html`](@ref) which wraps around Julia's Markdown to HTML.

Finally the function [`JuDoc.convert_inter_html`](@ref) takes the partial markdown and inserts the appropriately processed blocks where the `##JDINSERT##` are.
The function [`JuDoc.convert_block`](@ref) takes care of how blocks are converted before insertion (for instance how a math block should be properly fenced).

### HTML conversion

The core function corresponding to the conversion of a html document is, as mentioned before, [`JuDoc.convert_html`](@ref).
The first part corresponds to the parsing discussed above to find:

1. tokens
1. open/close blocks
1. conditional blocks (`if ... elseif ... else ... end`)
1. conditional def blocks (`isdef ... end`)
1. conditional page blocks (`ifpage ... end`)

The final HTML page is written by sequentially writing what's between the blocks and then replacing the blocks by the appropriate content using the function [`JuDoc.convert_hblock`](@ref).
