#=
Functionalities to take a string corresponding to Julia code and evaluate
that code in a given module while capturing stdout and redirecting it to
a file.
=#

"""
$SIGNATURES

Consumes a string with Julia code, returns a vector of expression(s).

Note: this function was adapted from the `parse_input` function from Weave.jl.
"""
function parse_code(code::AS)
    exs = Any[] # Expr, Symbol or Any Julia core value
    n   = sizeof(code)
    pos = 1
    while pos ≤ n
        ex, pos = Meta.parse(code, pos)
        isnothing(ex) && continue
        push!(exs, ex)
    end
    exs
end

"""
$SIGNATURES

Run some code in a given module while redirecting stdout to a given path.
Return the result of the evaluation or `nothing` if the code was empty or
the evaluation failed.
If the evaluation errors, the error is printed to output then a warning is
shown.

## Arguments

1. `mod`:      the module in which to evaluate the code,
1. `code`:     string corresponding to the code,
1. `out_path`: path where stdout should be redirected

## Keywords

* `warn_err=true`:  whether to show a warning in the REPL if there was an error
                    running the code.
* `strip=false`:    whether to strip the code, this may already have been done.
"""
function run_code(mod::Module, code::AS, out_path::AS;
                  warn_err::Bool=true, strip_code::Bool=true)
    isempty(code) && return nothing
    strip_code && (code = strip(code))
    exs  = parse_code(strip(code))
    ne   = length(exs)
    res  = nothing # to capture final result
    err  = nothing
    ispath(out_path) || mkpath(dirname(out_path))
    open(out_path, "w") do outf
        if !FD_ENV[:SILENT_MODE]
            rprint("→ evaluating code [$(out_path |> basename |> splitext |> first)] in ($(locvar("fd_rpath")))")
        end
        redirect_stdout(outf) do
            e = 1
            while e <= ne
                try
                    res = Core.eval(mod, exs[e])
                catch e
                    io = IOBuffer()
                    showerror(io, e)
                    println(String(take!(io)))
                    err = typeof(e)

                    # Print stacktrace.
                    for (exc, bt) in Base.catch_stack()
                        showerror(stderr, exc, bt)
                        println(stderr, "")
                    end

                    break
                end
                e += 1
            end
        end
    end
    # if there was an error, return nothing and possibly show warning
    if !isnothing(err)
        # TODO: add more informative message, maybe show type of error
        # + parent path
        FD_ENV[:SILENT_MODE] || print("\n")
        warn_err && print_warning("""
            There was an error of type '$err' when running a code block.
            Checking the output files '$(splitext(out_path)[1]).(out|res)'
            might be helpful to understand and solve the issue.
            \nRelevant pointers:
            $POINTER_EVAL
            """)
        res = nothing
    end
    # if last bit ends with `;` return nothing (no display)
    endswith(code, r";\s*") && return nothing
    # if last line is a Julia value return
    isa(exs[end], Expr) || return res
    # if last line of the code is a `show`
    if length(exs[end].args) > 1 && exs[end].args[1] == Symbol("@show")
        return nothing
    end
    # otherwise return the result of the last expression
    return res
end
