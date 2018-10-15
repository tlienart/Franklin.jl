# Rough Notes

This should eventually be compiled into proper documentation.

## Serving with browser-sync

* using `browser-sync` in `JuDoc.serve` to launch a local server and refresh the page upon modification of the source file
* when shutting down `JuDoc.serve` with a `CTRL+C` this propagates to the `browser-sync` process (a `node` process) which gets killed "properly"
* if `JuDoc.serve` gets an error (for example erroneous syntax somewhere), then the `browser-sync` process must be forcibly interrupted as there is no propagated interrupt signal, this is done by
    * writing the PID to a temporary file (`JuDoc.PID_FILE`) when launching the `browser-sync` process
    * upon anormal interruption, kill the process (see `JuDoc.cleanup_process()`)
    * remove the `PID_FILE`

**Note**: this should work fine on Linux/Mac, likely not on windows, but maybe with the emulator.

## Markdown Parsing

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
