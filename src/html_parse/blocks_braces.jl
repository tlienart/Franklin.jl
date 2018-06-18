#=
    {{ ... }} BLOCKS

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
        if haskey(BRACES_FUNS, fname)
            push!(replacements, BRACES_FUNS[fname](params, all_vars))
        else
            warn("I found a {{$fname...}} block but did not recognise the function name '$fname'. Ignoring.")
        end
    end
    interweave_rep(html_string, BRACES_BLOCK_SPLIT, replacements)
end


#=
    Braces functions

If extending, add the function in the BRACES_FUNS further below.
=#


"""
    braces_fill(params, all_vars)

Replacement for a block of the form `{{ fill vname }}` where `vname` is a key
in the `all_vars` dict assumed to be contained in `params`.
"""
function braces_fill(params, all_vars)
    replacement = ""

    # checking that got single parameter (1)
    ok_nargs, sparams = split_params(params, "fill", 1)
    vname = ok_nargs ? sparams : ""

    # provided there's 1 and only 1 arg
    if ok_nargs
        if haskey(all_vars, vname)
            tmp_repl = all_vars[vname].first # get the value stored
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
    braces_insert(params, all_vars)

Replacement for a block of the form `{{ insert filename }}`. The `params`
string is assumed to be composed of `fname`;  the name of the html file
(without extension) to insert (note that the base path is assumed to be
`JD_PATHS[:in_html]` so paths have to be expressed relative to that).
"""
function braces_insert(params, all_vars)
    replacement = ""

    # checking that got appropriate numbers of parameters
    ok_nargs, sparams = split_params(params, "insert", 1)
    fname = ok_nargs ? sparams : ""

    # correct number of arguments
    if ok_nargs
        filepath = JD_PATHS[:in_html] * fname * ".html"
        if isfile(filepath)
            replacement = readstring(filepath)
        else
            warn("I tried to insert '$filepath' but I couldn't find the file. Ignoring.")
        end
    end
    return replacement
end


# NOTE this has to come after the definitions otherwise ill posed.
const BRACES_FUNS = Dict(
    "fill" => braces_fill, # fill value contained in vars
    "insert" => braces_insert # insert file
    )
