st = raw"""
    Simple code:
    ```julia:scripts/test1
    a = 5
    println(a^2)
    ```
    done.
    """ * J.EOS

J.def_GLOB_VARS!()
J.def_GLOB_LXDEFS!()

m, _ = J.convert_md(st, collect(values(J.JD_GLOB_LXDEFS)))
h = J.convert_html(m, J.JD_VAR_TYPE())
