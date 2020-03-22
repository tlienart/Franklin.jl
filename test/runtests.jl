using Franklin, Test, Markdown, Dates, Random, Literate
const F = Franklin
const R = @__DIR__
const D = joinpath(dirname(dirname(pathof(Franklin))), "test", "_dummies")

F.FD_ENV[:SILENT_MODE] = true
F.FD_ENV[:STRUCTURE] = v"0.1" # legacy, it's switched up in the tests.

# UTILS
println("UTILS-1")
include("utils/folder_structure.jl")
include("utils/paths_vars.jl"); include("test_utils.jl")

println("UTILS-2")
include("utils/misc.jl")
include("utils/errors.jl")
include("utils/html.jl")
include("regexes.jl")
println("🍺")

# MANAGER folder
println("MANAGER")
include("manager/utils.jl")
include("manager/utils_fs2.jl")
include("manager/rss.jl")
include("manager/config.jl")
include("manager/config_fs2.jl")
include("manager/dir_utils.jl")
include("manager/page_vars_html.jl")
println("🍺")

# PARSER folder
println("PARSER/MD+LX")
include("parser/1-tokenize.jl")
include("parser/2-blocks.jl")
include("parser/markdown+latex.jl")
include("parser/markdown-extra.jl")
include("parser/footnotes+links.jl")
println("🍺")

# EVAL
println("EVAL")
include("eval/module.jl")
include("eval/run.jl")
include("eval/io.jl")
include("eval/io_fs2.jl")
include("eval/codeblock.jl")
include("eval/eval.jl")
include("eval/eval_fs2.jl")
include("eval/integration.jl")
include("eval/extras.jl")

# CONVERTER folder
println("CONVERTER/MD")
include("converter/markdown.jl")
include("converter/markdown2.jl")
include("converter/markdown3.jl")
include("converter/markdown4.jl")
include("converter/hyperref.jl")
include("converter/md_defs.jl")
println("🍺")
println("CONVERTER/HTML")
include("converter/html.jl")
include("converter/html2.jl")
include("converter/html_for.jl")
println("🍺")
println("CONVERTER/LX")
include("converter/lx_input.jl")
include("converter/lx_simple.jl")
include("converter/lx_simple_fs2.jl")
println("🍺")

fs2()

println("GLOBAL")
include("global/cases1.jl")
include("global/cases2.jl")
include("global/ordering.jl")
include("global/html_esc.jl")

begin
    # create temp dir to do complete integration testing (has to be here in
    # order to locally play nice with node variables etc, otherwise it's a big
    # headache)
    p = joinpath(D, "..", "__tmp");
    # after errors, this may not have been deleted properly
    isdir(p) && rm(p; recursive=true, force=true)
    # make dir, go in it, do the tests, then get completely out (otherwise
    # windows can't delete the folder)
    mkdir(p); cd(p);
    include("global/postprocess.jl");
    include("global/rss.jl")
    cd(p)
    include("global/eval.jl")
    cd(joinpath(D, ".."))
    # clean up
    rm(p; recursive=true, force=true)
end
cd(dirname(dirname(pathof(Franklin))))

println("TEMPLATING")
include("templating/for.jl")

println("INTEGRATION")
include("integration/literate.jl")
include("integration/literate_fs2.jl")
include("integration/literate_extras.jl")

flush_td()
cd(joinpath(dirname(dirname(pathof(Franklin)))))

println("COVERAGE")
include("coverage/extras1.jl")
include("coverage/paths.jl")

println("😅 😅 😅 😅")

# check quickly if the IPs in IP_CHECK are still ok
println("Verifying ip addresses, if online these should succeed.")
for (addr, name) in F.IP_CHECK
    println(rpad("Ping $name:", 13), ifelse(F.check_ping(addr), "✓", "✗"), ".")
end
