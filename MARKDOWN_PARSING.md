# Markdown Parsing

## Todo

* [ ] make the extended markdown parsing a standalone thing separated from the html parsing to make code easier to navigate
* [x] ~~rename `extract_page_defs` into `get_page_vars_defs`~~
* [x] rename `asym_math_blocks` into `extract_asym_math_blocks`
* [x] rename `sym_math_blocks` into `extract_sym_math_blocks`
* [ ] rename `div_blocks` into `get_div_blocks`
* [ ] make `@def` blocks have an equal sign.
* [ ] change way div are processed --> it should just be a simple replacement, no need for processing in fact. this means that nesting is then not necessary.
    * `@@name` --> `##DIV:name##` (so that not translated)
    * `@@` --? `##ENDDIV##`
    * then after html conversion: `##DIV:name##` --> `<div class="name">` and `##ENDDIV##` --> `</div>`.

**NOTE**

- block patterns are only used for markdown parsing

## Currently allowed

### Order of operations

#### extraction (parsing)

1. Removal of comments `<!-- ... -->` via `remove_comments`
    * return a `mdstring` without comments
1. Extraction of local page variables definitions `@def hasmath = true` via `extract_page_defs`
    * fill `JD_LOC_VARS` appropriately (see `set_vars!`)
    * return a `mdstring` without `@def...`
1. (**TODO**) Finding all `\def{...}` and add them to a dictionary of replacers
    * fill `JD_COMMANDS`
    * return a `mdstring` without `\def{...}`
1. (**TODO**) Finding all `\coms{...}` from the dictionary of replacers (also global defined in `config.md`)
    * return a `mdstring` where the `\coms{...}` have been adequately replaced (e.g.: if there's a `\def{\R}{\mathbb R}`)
1. Extract all math blocks (*nesting not allowed* content will be plugged as is in `KaTex`)
    * return a `mdstring` where the math blocks have been replaced by placeholders
1. Extract all div blocks
    * **FUTURE** nesting allowed, recursive processing allowing divs within divs. (Discuss use case)
    * return a `mdstring` where the div blocks have been replaced by placeholders

#### Writing (processing)

1. Generic Markdown -> HTML translation using Julia's Markdown parser
1. Filling the div-blocks
1. Filling the math-blocks


## Sandbox

### Parser open-close

```julia
omatch = matchall(r"@@([a-zA-Z]\S*)", tst)
cmatch = matchall(r"@@(\s|\n|$)", tst)

levels = Vector{Int}(length(omatch))
pairs = Vector{Pair{SubString, SubString}}(length(omatch))

ooff = [om.offset for om ∈ omatch]

for (i, cm) ∈ enumerate(cmatch)
    coff = cm.offset
    idx = find(ooff .> coff)
    idx = isempty(idx) ? 1 : idx[1] - 1
    levels[i] = idx
    pairs[i] = omatch[idx]=>cm
    deleteat!(ooff, idx)
    deleteat!(omatch, idx)
end
```

does an ok job. not clear whether we'd actually need nesting .
