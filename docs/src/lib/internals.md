# Internal Interface

Documentation for `JuDoc.jl`'s internal interface.

## File processing and compilation

```@docs
JuDoc.jd_setup
JuDoc.jd_fullpass
JuDoc.jd_loop
JuDoc.process_file
JuDoc.process_file_err
```

## Conversion

```@docs
JuDoc.write_page
JuDoc.convert_md
JuDoc.form_inter_md
JuDoc.md2html
JuDoc.convert_inter_html
JuDoc.convert_block
JuDoc.convert_html
JuDoc.convert_hblock
JuDoc.build_page
```

### Pre-rendering

```@docs
JuDoc.js_prerender_katex
JuDoc.js_prerender_highlight
```

## Parsing

```@docs
JuDoc.AbstractBlock
JuDoc.Token
JuDoc.OCBlock
JuDoc.TokenFinder
JuDoc.MD_TOKENS
JuDoc.MD_1C_TOKENS
JuDoc.LxDef
JuDoc.LxCom
JuDoc.HTML_TOKENS
JuDoc.HTML_OCB
```

```@docs
JuDoc.isexactly
JuDoc.find_tokens
JuDoc.find_all_ocblocks
JuDoc.find_md_lxdefs
JuDoc.find_md_lxcoms
JuDoc.qualify_html_hblocks
JuDoc.find_html_cblocks
JuDoc.JuDoc.find_html_cdblocks
JuDoc.JuDoc.find_html_cpblocks
```
