# Internal Interface

Documentation for `JuDoc.jl`'s internal interface.

## Compilation

```@docs
JuDoc.jd_setup
JuDoc.jd_fullpass
JuDoc.jd_loop
```

## Files and directories

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
