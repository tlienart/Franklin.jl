#=
    [[ CTRL_TOKEN VAR ... ]]

NOTE: nesting is not (yet) allowed (it's meant to be rudimentary so that blocks
can just be obtained via simple regex). There's not yet a clear use case for
nesting.
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
            push!(replacements, all_vars[vname].first ? block : "")
        else
            warn("I found a [[if $vname ... ]] block but I don't know the variable '$vname'. Default assumption = it's false.")
        end
    end
    interweave_rep(html_string, IF_SQBR_BLOCK_SPLIT, replacements)
end
