# Markdown Parsing

## Todo

* [ ] make the extended markdown parsing a standalone thing separated from the html parsing to make code easier to navigate
* [ ] rename `extract_page_defs` into `get_page_vars_defs`
* [ ] rename `asym_math_blocks` into `get_asym_math_blocks`
* [ ] rename `sym_math_blocks` into `get_sym_math_blocks`
* [ ] join the extraction of asym and sym math blocks
* [ ] rename `div_blocks` into `get_div_blocks`

## Currently allowed

### Order of operations

1. Removal of comments `<!-- ... -->` via `remove_comments`
    * return a `mdstring` without comments
1. Extraction of local page variables definitions `@def hasmath = true` via `extract_page_defs`
    * fill `JD_LOC_VARS` appropriately (see `set_vars!`)
    * return a `mdstring` without `@def...`
1. (**TODO**) Finding all `\def{...}` and add them to a dictionary of replacers
    * fill `JD_COMMANDS`
1. (**TODO**) Finding all `\coms{...}` from the dictionary of replacers (also global defined in `config.md`)
1. Extract all math blocks (*nesting not allowed*)
1. Extract all div blocks ()
1. Generic Markdown -> HTML translation using Julia's Markdown parser
