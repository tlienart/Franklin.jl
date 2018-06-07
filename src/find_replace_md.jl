"""
    asym_math_blocks(md_string)

Capture asymmetric block maths expressions such as `\\begin{...}...\\end{...}`.
"""
function asym_math_blocks(md_string)
    # container for recovered expressions (bm for "block math")
    asym_mb = Tuple{BlockPat, String}[]
    counter = 1
    for bpat ∈ ASYM_MATH
        re = regex(bpat)
        for m ∈ eachmatch(re, md_string)
            # store the content of the block
            push!(asym_mb, (bpat, String(m.captures[1])))
            # replace it by a numbered placeholder
            md_string = replace(md_string, re, ASYM_MATH_PH * "$counter", 1)
            counter += 1
        end
    end
    return (md_string, asym_mb)
end


"""
    sym_math_blocks(md_string)

Capture symmetric block maths expressions such as `\$\$...\$\$`.
(Difference with asym is that the function needs to differentiate between
opening and closing symbol).
"""
function sym_math_blocks(md_string)
    # container for recovered expressions (bm for "block math")
    sym_mb = Tuple{BlockPat, String}[]
    counter = 1
    for bpat ∈ SYM_MATH
        re = regex(bpat)
        has_pat = true
        while has_pat
            rge_pat = search(md_string, re)
            has_pat = !isempty(rge_pat)
            if has_pat
                # extract and store the content of the block
                off = bpat.sym_offset
                inner = md_string[rge_pat][(1+off):(end-off)]
                push!(sym_mb, (bpat, inner))
                # replace it by a numbered placeholder
                pre, post = rge_pat.start-1, rge_pat.stop+1
                tmp = SYM_MATH_PH * "$counter"
                md_string = md_string[1:pre] * tmp * md_string[post:end]
                counter += 1
            end
        end
    end
    return (md_string, sym_mb)
end


"""
    div_blocks(md_string)

Capture div blocks expressions of the form `@@nameofdiv ... @@`.
(Difference with asym math is that the name of the block must be recovered)
"""
function div_blocks(md_string)
    # container for recovered expressions (div block)
    div_b = Tuple{String, String}[]
    counter = 1
    for m ∈ eachmatch(DIV, md_string)
        # extract and store the content of the block
        push!(div_b, (String(m.captures[1]), String(m.captures[2])))
        # replace it by a numbered placeholder
        md_string = replace(md_string, DIV, DIV_PH * "$counter", 1)
        counter += 1
    end
    return (md_string, div_b)
end


"""
    remove_comments(md_string)

Find blocks between `<!--` and `-->` and remove them.
"""
remove_comments(md_string) = replace(md_string, COMMENTS, "")


"""
    extract_page_defs(md_string, var_dict)

Capture lines of the form `@def VARNAME VALUE`
"""
function extract_page_defs(md_string)
    # container for recovered definitions
    defs = Pair{String, String}[]
    for m ∈ eachmatch(DEFS, md_string)
        # extract and store recovered definition
        push!(defs, String(m.captures[1])=>String(m.captures[2]))
    end
    md_string = replace(md_string, DEFS, "")
    return (md_string, defs)
end
