
"""
$SIGNATURES

Internal function to check if a code should suppress the final show.
"""
function check_suppress_show(code::AS)
    scode = strip(code)
    scode[end] == ';' && return true
    # last line ?
    lastline = scode
    i = findlast(e -> e in (';','\n'), scode)
    if !isnothing(i)
        lastline = strip(scode[nextind(scode, i):end])
    end
    startswith(lastline, "@show ")   && return true
    startswith(lastline, "println(") && return true
    startswith(lastline, "print(")   && return true
    return false
end
"""
$SIGNATURES

Internal function to read the output and result files resulting from the eval
of a code block and return a string with whatever is appropriate.
"""
function show_res(rpath::AS)::String
    fpath, = check_input_rpath(rpath; code=true)
    fd, fn = splitdir(fpath)
    stdo   = read(joinpath(fd, "output", splitext(fn)[1] * ".out"), String)
    res    = read(joinpath(fd, "output", splitext(fn)[1] * ".res"), String)
    # check if there's a final `;` or if the last line is a print, println or show
    # in those cases, ignore the result file
    code = strip(read(splitext(fpath)[1] * ".jl", String))
    check_suppress_show(code) && (res = "")
    if !isempty(stdo)
        endswith(stdo, "\n") || (stdo *= "\n")
    end
    res == "nothing" && (res = "")
    isempty(stdo) && isempty(res) && return ""
    return html_div("code_output", html_code(stdo * res))
end
