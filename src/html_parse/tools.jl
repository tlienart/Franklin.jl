"""
    interweave_rep(html_string, splitter, replacements)

Finds blocks of a specific form (given by `splitter`) in the `html_string` and
return the `html_string` with each of the `replacements` instead of the blocks.
"""
function interweave_rep(html_string, splitter, replacements)
    split_html_string = split(html_string, splitter)
    html_string = split_html_string[1]
    for (c, rep) ∈ enumerate(replacements)
        html_string *= rep * split_html_string[c+1]
    end
    return html_string
end


"""
    split_params(params, fun_name, expect_args)

Helper function to split a string `params` expected to contain references to
parameters for `fun_name` in number `expect_args`. If that's not the case,
with either too few or too many arguments, a warning is returned and the action
will be ignored.
"""
function split_params(params, fun_name, expect_args)
    sparams = split(params)
    len_sparams = length(sparams)
    flag = (len_sparams == expect_args)
    if !flag
        warn("I found a '$fun_name' and expected $expect_args argument(s) but got $len_sparams instead. Ignoring.")
    end
    return (flag, (len_sparams == 1) ? sparams[1] : sparams)
end

#=
    Processing html blocks

Chaining operations.
=#


"""
    ⊙(f, g)

Partial composition of two functions of two variables.
Amounts to f(g(x, y), y). This is just for convenience and not very useful.
"""
⊙(f::Function, g::Function) = (x, y)->f(g(x, y), y)


"""
    process_html_blocks(html_string, all_vars)

Find `[[...]]` and `{{...}}` blocks and modify `html_string`
accordingly. `[[...]]` are processed first.
"""
process_html_blocks = process_braces_blocks ⊙ process_if_sqbr_blocks
