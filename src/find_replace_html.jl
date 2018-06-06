#=
    MATHS + DIV BLOCKS
=#

dpat(div_name, content) = "<div class=\"$div_name\">$content</div>\n"


"""
    process_math_blocks(html_string, asym_bm, sym_bm)

Take a string representing a html file, finds the placeholders left by
    - asym_math_blocks!
    - sym_math_blocks!
and plugs back in the KaTeX compatible corresponding content.
"""
function process_math_blocks(html_string, asym_bm, sym_bm)
    # first ASYM then SYM
    for (PH, blocks) ∈ zip([ASYM_MATH_PH, SYM_MATH_PH], [asym_bm, sym_bm])
        for (i, (mpat, elem)) ∈ enumerate(blocks)
            html_string = replace(html_string, PH * "$i", mpat(elem), 1)
        end
    end
    return html_string
end


"""
    process_div_blocks(html_string, div_b)

Same as for math block with the difference that it processes the name of the
div block.
"""
function process_div_blocks(html_string, div_b)
    for (i, (dname, content)) ∈ enumerate(div_b)
        html_string = replace(html_string,
                                "##DIV_BLOCK##$i", dpat(dname, content), 1)
    end
    return html_string
end

"""
    interweave_rep(html_string, splitter, replacements)

Finds blocks of a specific form (given by `splitter`) in the `html_string` and
return the `html_string` with each of the `replacements` instead of the blocks.
"""
function interweave_rep(html_string, splitter, replacements)
    split_html_string = split(html_string, splitter)
    cntr = 1
    html_string = split_html_string[cntr]
    for rep ∈ replacements
        html_string *= rep
        html_string *= split_html_string[cntr+1]
        cntr += 1
    end
    return html_string
end

#=
    [[ CTRL_TOKEN VAR ... ]]

NOTE:
 - nesting is NOT allowed (it's meant to be very rudimentary so that
blocks can just be obtained via regex. To make nesting possible, would
need to learn how to parse... just a bit over the top for now.
=#
const IF_SQBR_BLOCK = r"\[\[\s*if\s+([a-z]\S+)((.|\n)+?)\]\]"
const IF_SQBR_BLOCK_SPLIT = r"\[\[\s*if\s(.|\n)+?\]\]"

"""
    process_if_sqbr_blocks(html_string, all_vars)

Find blocks of the form `[[ if var ... ]]` where `var` is a variable
referenced in the `all_vars` dict corresponding to a boolean. If the bool
is false or does not exist, the block is not reproduced. If the bool is true,
the block is inserted (and further processed).
"""
function process_if_sqbr_blocks(html_string, all_vars)
    replacements = String[]
    for m ∈ eachmatch(IF_SQBR_BLOCK, html_string)
        vname = m.captures[1]
        block = m.captures[2]
        if haskey(all_vars, vname)
            push!(replacements, all_vars[vname] ? block : "")
        else
            warn("I found a [[if $vname ... ]] block but I don't know the variable '$vname'. Default assumption = it's false.")
        end
    end
    interweave_rep(html_string, IF_SQBR_BLOCK_SPLIT, replacements)
end


#=
    {{ ... }} BLOCKS

NOTE if adding new functionalities, don't forget to add them to the collection
`braces_funs` at the bottom.
NOTE assumption that the braces blocks are closed properly...
=#
const BRACES_BLOCK = r"{{\s*([a-z]\S+)\s+((.|\n)+?)}}"
const BRACES_BLOCK_SPLIT = r"{{(.|\n)+?}}"

"""
    process_braces_blocks(html_string, all_vars)

Find blocks of the form `{{ fname param₁ param₂ }}`, modify `html_string`
accordingly by calling the function `fname`.
"""
function process_braces_blocks(html_string, all_vars)
    replacements = String[]
    for m ∈ eachmatch(BRACES_BLOCK, html_string)
        fname = m.captures[1]
        params = m.captures[2]
        if haskey(braces_funs, fname)
            push!(replacements, braces_funs[fname](params, all_vars))
        else
            warn("I found a {{$fname...}} block but did not recognise the function name '$fname'. Ignoring.")
        end
    end
    interweave_rep(html_string, BRACES_BLOCK_SPLIT, replacements)
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


"""
    braces_fill(params, all_vars)

Replacement for a block of the form `{{ fill vname }}` where `vname` is a key
in the `all_vars` dict assumed to be contained in `params`.
"""
function braces_fill(params, all_vars)
    replacement = ""

    # checking that got appropriate numbers of parameters
    ok_nargs, sparams = split_params(params, "fill", 1)
    vname = ok_nargs ? sparams : ""

    # correct number of arguments
    if ok_nargs
        if haskey(all_vars, vname)
            tmp_repl = all_vars[vname][1] # get the value stored
            if !(tmp_repl == nothing)
                replacement = string(tmp_repl)
            end
        else
            warn("I found a '{{fill $vname}}' but I do not know the variable '$vname'. Ignoring.")
        end
    end # the case where narg is incorrect raises a warning via split_params

    return replacement
end


"""
    braces_insert_if(params, all_vars)

Replacement for a block of the form `{{ insert_if boolvar filename }}`.
The `params` string is assumed to be composed of `vname` and `fname`.
The `vname` variable is the name of a boolean variable stored in the `all_vars`
dictionary indicating whether or not to insert and `fname` is the name
of the file to insert (note that the base path is JD_PATHS[:in_html]).
"""
function braces_insert_if(params, all_vars)
    replacement = ""

    # checking that got appropriate numbers of parameters
    ok_nargs, sparams = split_params(params, "insert_if", 2)
    vname, fname = ok_nargs ? sparams : ["", ""]

    # correct number of arguments
    if ok_nargs
        if haskey(all_vars, vname)
            filepath = JD_PATHS[:in_html] * fname * ".html"
            if isfile(filepath)
                replacement = all_vars[vname][1] ? readstring(filepath) : ""
            else
                warn("I tried to insert '$filepath' but I couldn't find the file. Ignoring.")
            end
        else
            warn("I found an '{{insert_if $vname ...}}' but I do not know the variable '$vname'. Ignoring.")
        end
    end
    return replacement
end


# NOTE this has to come after the definitions otherwise ill posed.
const braces_funs = Dict(
    "fill" => braces_fill, # fill value contained in vars
    "insert_if" => braces_insert_if # insert file if condition is met
    )
