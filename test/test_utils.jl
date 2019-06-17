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

# this is a slightly ridiculous requirement but apparently the `eval` blocks
# don't play well with Travis nor windows while testing, so you just need to forcibly
# specify that LinearAlgebra and Random are used (even though the included block says
# the same thing).
if get(ENV, "CI", "false") == "true" || Sys.iswindows()
    import Pkg; Pkg.add("LinearAlgebra"); Pkg.add("Random");
    using LinearAlgebra, Random;
end

# takes md input and outputs the html (good for integration testing)
function seval(st)
    J.def_GLOB_VARS!()
    J.def_GLOB_LXDEFS!()
    m, _ = J.convert_md(st, collect(values(J.JD_GLOB_LXDEFS)))
    h = J.convert_html(m, J.JD_VAR_TYPE())
    return h
end
