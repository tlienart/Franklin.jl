# Internal Interface

Documentation for `JuDoc.jl`'s internal interface.

## Parsing and Conversion

See `src/converter/*`, and `src/parser/*`.

### General

See `src/parser/tokens.jl` and `src/parser/ocblocks.jl`

**Types** and **Constants**

```@docs
JuDoc.AbstractBlock
JuDoc.Token
JuDoc.OCBlock
JuDoc.EOS
JuDoc.SPACER
JuDoc.TokenFinder
```

**Methods**

```@docs
JuDoc.otok
JuDoc.ctok
JuDoc.content
JuDoc.isexactly
JuDoc.α
JuDoc.incrlook
JuDoc.find_tokens
JuDoc.find_ocblocks
JuDoc.ocbalance
JuDoc.find_all_ocblocks
JuDoc.merge_blocks
```

### Markdown

See `src/parser/tokens_md.jl` and `src/converter/md*`.

**Constants**

```@docs
JuDoc.MD_1C_TOKENS
JuDoc.MD_1C_TOKENS_LX
JuDoc.MD_TOKENS
JuDoc.MD_TOKENS_LX
JuDoc.MD_DEF_PAT
JuDoc.MD_OCB
JuDoc.MD_OCB_MATH
JuDoc.MD_OCB_IGNORE
JuDoc.MD_MATH_NAMES
JuDoc.JD_INSERT
JuDoc.JD_MBLOCKS_PM
```

**Methods**

```@docs
JuDoc.convert_md
JuDoc.convert_md_math
JuDoc.form_inter_md
JuDoc.convert_inter_html
JuDoc.process_md_defs
JuDoc.md2html
JuDoc.from_ifsmaller
JuDoc.deactivate_divs
JuDoc.convert_block
JuDoc.convert_mathblock
JuDoc.convert_code_block
```

### LaTeX

See `src/parser/tokens_lx.jl`, `src/parser/lxblocks.jl`.

**Types** and **Constants**

```@docs
JuDoc.LX_NAME_PAT
JuDoc.LX_NARG_PAT
JuDoc.LX_TOKENS
JuDoc.LxDef
JuDoc.LxCom
JuDoc.LxContext
```

**Methods**

```@docs
JuDoc.pastdef
JuDoc.getdef
JuDoc.find_md_lxdefs
JuDoc.retrieve_lxdefref
JuDoc.find_md_lxcoms
```

### HTML

See `src/parser/tokens_html.jl` and `src/parser/hblocks.jl`.

**Types** and **Constants**

```@docs
JuDoc.HTML_1C_TOKENS
JuDoc.HTML_TOKENS
JuDoc.HTML_OCB
JuDoc.HBLOCK_IF
JuDoc.HTML_1C_TOKENS
JuDoc.HBLOCK_IF_PAT
JuDoc.HBLOCK_ELSE_PAT
JuDoc.HBLOCK_ELSEIF_PAT
JuDoc.HBLOCK_END_PAT
JuDoc.HBLOCK_ISDEF_PAT
JuDoc.HBLOCK_ISNOTDEF_PAT
JuDoc.HBLOCK_ISPAGE_PAT
JuDoc.HBLOCK_ISNOTPAGE_PAT
JuDoc.HIf
JuDoc.HElse
JuDoc.HElseIf
JuDoc.HEnd
JuDoc.HCond
JuDoc.HIsDef
JuDoc.HIsNotDef
JuDoc.HCondDef
JuDoc.HIsPage
JuDoc.HIsNotPage
JuDoc.HCondPage
JuDoc.HBLOCK_FUN_PAT
JuDoc.HFun
```

**Methods**

```@docs
JuDoc.qualify_html_hblocks
JuDoc.find_html_cblocks
JuDoc.find_html_cdblocks
JuDoc.find_html_cpblocks
```

## Compilation

See `src/manager/judoc.jl`.

```@docs
JuDoc.jd_setup
JuDoc.jd_fullpass
JuDoc.jd_loop
```

## Page variables

See `src/jd_vars`.

**Variables**

```@docs
JuDoc.JD_GLOB_VARS
JuDoc.JD_LOC_VARS
JuDoc.JD_GLOB_LXDEFS
```

**Methods**

```@docs
JuDoc.def_GLOB_VARS!
JuDoc.def_LOC_VARS!
JuDoc.def_GLOB_LXDEFS!
```

**Helper functions**

```@docs
JuDoc.jd_date
JuDoc.is_ok_type
JuDoc.set_var!
JuDoc.set_vars!
```

## Path variables

**Variables**

```@docs
JuDoc.JD_FOLDER_PATH
JuDoc.JD_IGNORE_FILES
JuDoc.JD_INFRA_EXT
JuDoc.JD_PATHS
```

**Methods**

```@docs
JuDoc.set_paths!
```

## Files and directories

See `src/manager/dir_utils.jl` and `src/manager/file_utils.jl`.

### File management

```@docs
JuDoc.process_config
JuDoc.write_page
JuDoc.process_file_err
```

### Dir management

```@docs
JuDoc.prepare_output_dir
JuDoc.out_path
JuDoc.scan_input_dir!
JuDoc.add_if_new_file!
```

### Helper functions

```@docs
JuDoc.process_file
JuDoc.change_ext
JuDoc.build_page
```

## Miscellaneous

### String and substring processing

```@docs
JuDoc.str
JuDoc.subs
JuDoc.from
JuDoc.to
JuDoc.matchrange
```

### Other

```@docs
JuDoc.time_it_took
JuDoc.isnothing
JuDoc.mathenv
JuDoc.refstring
```

## Environment variables

See `src/JuDoc.jl`.

```@docs
JuDoc.JD_SERVE_FIRSTCALL
JuDoc.JD_DEBUG
JuDoc.HIGHLIGHT
JuDoc.JUDOC_PATH
JuDoc.TEMPL_PATH
```

## External

See `src/build.jl`

```@docs
JuDoc.JD_HAS_PY3
JuDoc.JD_HAS_PIP3
JuDoc.JD_CAN_MINIFY
JuDoc.CAN_PRERENDER
JuDoc.CAN_HIGHLIGHT
```
