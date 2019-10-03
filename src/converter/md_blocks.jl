"""
$(SIGNATURES)

Helper function for `convert_inter_html` that processes an extracted block given a latex context
`lxc` and returns the processed html that needs to be plugged in the final html.
"""
function convert_block(β::AbstractBlock, lxcontext::LxContext)::AS
    # case for special characters / html entities
    β isa HTML_SPCH     && return ifelse(isempty(β.r), β.ss, β.r)
    # Return relevant interpolated string based on case
    βn = β.name
    βn ∈  MD_HEADER        && return convert_header(β)
    βn == :CODE_INLINE     && return html_code_inline(content(β) |> htmlesc)
    βn == :CODE_BLOCK_LANG && return convert_code_block(β.ss)
    βn == :CODE_BLOCK_IND  && return convert_indented_code_block(β.ss)
    βn == :CODE_BLOCK      && return html_code(strip(content(β)), "{{fill lang}}")
    βn == :ESCAPE          && return chop(β.ss, head=3, tail=3)
    βn == :FOOTNOTE_REF    && return convert_footnote_ref(β)
    βn == :FOOTNOTE_DEF    && return convert_footnote_def(β, lxcontext)
    βn == :LINK_DEF        && return ""

    # Math block --> needs to call further processing to resolve possible latex
    βn ∈ MATH_BLOCKS_NAMES && return convert_math_block(β, lxcontext.lxdefs)

    # Div block --> need to process the block as a sub-element
    if βn == :DIV
        ct, _ = convert_md(content(β) * EOS, lxcontext.lxdefs;
                           isrecursive=true, has_mddefs=false)
        name = chop(otok(β).ss, head=2, tail=0)
        return html_div(name, ct)
    end

    # default case, ignore block (should not happen)
    return ""
end
convert_block(β::LxCom, λ::LxContext) = resolve_lxcom(β, λ.lxdefs)


"""
MATH_BLOCKS_PARENS

Dictionary to keep track of how math blocks are fenced in standard LaTeX and how these fences need
to be adapted for compatibility with KaTeX. Each tuple contains the number of characters to chop
off the front and the back of the maths expression (fences) as well as the KaTeX-compatible
replacement.
For instance, `\$ ... \$` will become `\\( ... \\)` chopping off 1 character at the front and the
back (`\$` sign).
"""
const MATH_BLOCKS_PARENS = LittleDict{Symbol, Tuple{Int,Int,String,String}}(
    :MATH_A     => ( 1,  1, "\\(", "\\)"),
    :MATH_B     => ( 2,  2, "\\[", "\\]"),
    :MATH_C     => ( 2,  2, "\\[", "\\]"),
    :MATH_ALIGN => (13, 11, "\\[\\begin{aligned}", "\\end{aligned}\\]"),
    :MATH_EQA   => (16, 14, "\\[\\begin{array}{c}", "\\end{array}\\]"),
    :MATH_I     => ( 4,  4, "", "")
    )


"""
$(SIGNATURES)

Helper function for the math block case of `convert_block` taking the inside of a math block,
resolving any latex command in it and returning the correct syntax that KaTeX can render.
"""
function convert_math_block(β::OCBlock, lxdefs::Vector{LxDef})::String
    # try to find the block out of `MATH_BLOCKS_PARENS`, if not found, error
    pm = get(MATH_BLOCKS_PARENS, β.name) do
        throw(MathBlockError("Unrecognised math block name."))
    end

    # convert the inside, decorate with KaTex and return, also act if
    # if the math block is a "display" one (with a number)
    inner = chop(β.ss, head=pm[1], tail=pm[2])
    htmls = IOBuffer()
    if β.name ∉ [:MATH_A, :MATH_I]
        # NOTE: in the future if allow equation tags, then will need an `if`
        # here and only increment if there's no tag. For now just use numbers.

        # increment equation counter
        PAGE_EQREFS[PAGE_EQREFS_COUNTER] += 1

        # check if there's a label, if there is, add that to the dictionary
        matched = match(r"\\label{(.*?)}", inner)

        if !isnothing(matched)
            name   = refstring(matched.captures[1])
            write(htmls, "<a id=\"$name\"></a>")
            inner  = replace(inner, r"\\label{.*?}" => "")
            # store the label name and associated number
            PAGE_EQREFS[name] = PAGE_EQREFS[PAGE_EQREFS_COUNTER]
        end
    end
    # assemble the katex decorators, the resolved content etc
    write(htmls, pm[3], convert_md_math(inner * EOS, lxdefs, from(β)), pm[4])
    return String(take!(htmls))
end


"""
$(SIGNATURES)

Helper function for the case of a header block (H1, ..., H6).
"""
function convert_header(β::OCBlock)::String
    hk       = lowercase(string(β.name)) # h1, h2, ...
    title, _ = convert_md(content(β) * EOS; isrecursive=true, has_mddefs=false)
    rstitle  = refstring(title)
    # check if the header has appeared before and if so suggest
    # an altered refstring; if that altered refstring also exist
    # (pathological case, see #241), then extend it with a letter
    # if that also exists (which would be really crazy) add a random
    # string
    keys_headers = keys(PAGE_HEADERS)
    if rstitle in keys_headers
        title, n, lvl = PAGE_HEADERS[rstitle]
        # then update the number of occurence
        PAGE_HEADERS[rstitle] = (title, n+1, lvl)
        # update the refstring, note the double _ (see refstring)
        rstitle *= "__$(n+1)"
        PAGE_HEADERS[rstitle] = (title, 0, parse(Int, hk[2]))
    else
        PAGE_HEADERS[rstitle] = (title, 1, parse(Int, hk[2]))
    end
    # return the title
    return html_hk(hk, html_ahref_key(rstitle, title); id=rstitle)
end

"""Convenience constant for an automatic message to add to code files."""
const MESSAGE_FILE_GEN = "# This file was generated by JuDoc, do not modify it. # hide\n"

"""
$SIGNATURES

Helper function to increment the local page variable `jd_code_n` which keeps track of which
eval'd code block we're looking at.
"""
function increment_code_n()::Int
    c = LOCAL_PAGE_VARS["jd_code_n"].first + 1
    set_var!(LOCAL_PAGE_VARS, "jd_code_n", c)
    return c
end

"""
$SIGNATURES

Helper function to eval a code block and write it where appropriate
"""
function eval_code_block(code::AS, path::String, out_path::String)::Nothing
    write(path, MESSAGE_FILE_GEN * code)
    # - execute the code while redirecting stdout to file
    open(out_path, "w") do outf
        redirect_stdout(outf)  do
            try
                Main.include(path)
            catch e
                print("There was an error running the code:\n$(e.error)")
            end
        end
    end
    return nothing
end

"""
$(SIGNATURES)

Helper function for the code block case of `convert_block`.
"""
function convert_code_block(ss::SubString)::String
    fencer = ifelse(startswith(ss, "`````"), "`````", "```")
    reg    = Regex("$fencer([a-z-]*)(\\:[a-zA-Z\\\\\\/-_\\.]+)?\\s*\\n?((?:.|\\n)*)$fencer")
    m      = match(reg, ss)
    lang  = m.captures[1]
    rpath = m.captures[2]
    code  = m.captures[3]

    # if no rpath is given, the code is not eval'd
    if isnothing(rpath)
        return html_code(code, lang)
    end
    if lang!="julia"
        @warn "Eval of non-julia code blocks is not yet supported."
        return html_code(code, lang)
    end
    # path currently has an indicative `:` we don't care about
    rpath = rpath[2:end]

    # Here we have a julia code block that was provided with a script path
    # It will consequently be
    #   1. written to script file unless it's already there
    #   2. evaled (unless a file was there and output file is present), redirect out
    #   3. inserted after scrapping out lines (see resolve_lx_input)
    path = resolve_assets_rpath(rpath; canonical=true, code=true)

    endswith(path, ".jl") || (path *= ".jl")

    out_path, fname = splitdir(path)
    out_path = mkpath(joinpath(out_path, "output"))
    out_name = splitext(fname)[1] * ".out"
    out_path = joinpath(out_path, out_name)

    code_dict = LOCAL_PAGE_VARS["jd_code"].first

    # shortcut if forced
    if FORCE_REEVAL[]
        # append code block
        code_dict[rpath] = code
        # and eval
        eval_block(code, path, out_path)
    end

    # otherwise we're in the "constant eval" mode
    # > keep track of which eval'd code block it is (absolute numbering)
    c = increment_code_n()
    keys_ = keys(code_dict)

    update_dict = true
    eval_code   = true

    # compare to the current list of code blocks
    # a. (c ≤ current length) --> check that everything matches
    if (c ≤ length(code_dict)) && rpath in keys_ && code == code_dict[rpath]
        # don't need to update the dictionary
        update_dict = false
        # are the files there? in the unlikely case they got
        # removed or something, re-eval
        eval_code = !(isfile(path) && isfile(out_path))
    end
    # b. (c > length) --> add and eval

    if update_dict
        code_dict[rpath] = code
        if (c ≤ length(code_dict))
            # purge whatever is after (will be re-eval)
            foreach(k -> delete!(code_dict, k), collect(keys_)[c:end])
        end
    end

    eval_code && eval_code_block(code, path, out_path)

    # step 3, insertion of code stripping of "hide" lines.
    return resolve_lx_input_hlcode(rpath, "julia")
end


"""
$(SIGNATURES)

Helper function for the indented code block case of `convert_block`.
"""
function convert_indented_code_block(ss::SubString)::String
    # 1. decrease indentation of all lines (either frontal \n\t or \n⎵⎵⎵⎵)
    code = replace(ss, r"\n(?:\t| {4})" => "\n")
    # 2. return; lang is a LOCAL_PAGE_VARS that is julia by default and can be set
    sc = strip(code)
    isempty(sc) && return ""
    return html_code(sc, "{{fill lang}}")
end

"""
$(SIGNATURES)

Helper function to convert a `[^1]` into a html sup object with appropriate ref and backref.
"""
function convert_footnote_ref(β::Token)::String
    # β.ss is [^id]; extract id
    id = string(match(r"\[\^(.*?)\]", β.ss).captures[1])
    # add it to the list of refs unless it's been seen before
    pos = 0
    for (i, pri) in enumerate(PAGE_FNREFS)
        if pri == id
            pos = i
            break
        end
    end
    if pos == 0
        push!(PAGE_FNREFS, id)
        pos = length(PAGE_FNREFS)
    end
    return html_sup("fnref:$id", html_ahref(url_curpage() * "#fndef:$id", "[$pos]"; class="fnref"))
end

"""
$(SIGNATURES)

Helper function to convert a `[^1]: ...` into a html table for the def.
"""
function convert_footnote_def(β::OCBlock, lxcontext::LxContext)::String
    # otok(β) is [^id]:
    id = match(r"\[\^(.*?)\]:", otok(β).ss).captures[1]
    pos = 0
    for (i, pri) in enumerate(PAGE_FNREFS)
        if pri == id
            pos = i
            break
        end
    end
    if pos == 0
        # this was never referenced before, so probably best not to show it
        return ""
    end
    # need to process the content which could contain stuff
    ct, _ = convert_md(content(β) * EOS, lxcontext.lxdefs;
                       isrecursive=true, has_mddefs=false)
    """
    <table class="fndef" id="fndef:$id">
        <tr>
            <td class=\"fndef-backref\">$(html_ahref(url_curpage() * "#fnref:$id", "[$pos]"))</td>
            <td class=\"fndef-content\">$(ct)</td>
        </tr>
    </table>
    """
end
