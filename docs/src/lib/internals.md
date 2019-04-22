# Internal Interface

Documentation for `JuDoc.jl`'s internal interface.

## Parsing and Conversion

See `src/converter/*`, and `src/parser/*`.

### General

```@docs
JuDoc.AbstractBlock
JuDoc.Token
JuDoc.AbstractBlock
JuDoc.Token
JuDoc.OCBlock
JuDoc.EOS
JuDoc.SPACER
JuDoc.TokenFinder
JuDoc.otok
JuDoc.ctok
JuDoc.content
JuDoc.isexactly
JuDoc.α
JuDoc.incrlook
JuDoc.find_tokens
```

### Markdown

### LaTeX

### HTML

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
