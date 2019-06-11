# This set of tests directly uses the high-level `convert` functions
# And checks the behaviour is as expected.

J.def_GLOB_LXDEFS!()
cmd   = st -> J.convert_md(st, collect(values(J.JD_GLOB_LXDEFS)))
chtml = t -> J.convert_html(t...)
conv  = st -> st |> cmd |> chtml

# convenience function that squeezes out all whitespaces and line returns out of a string
# and checks if the resulting strings are equal. When expecting a specific string +- some
# spaces, this is very convenient. Use == if want to check exact strings.
isapproxstr(s1::String, s2::String) =
    isequal(map(s->replace(s, r"\s|\n"=>""), (s1, s2))...)
