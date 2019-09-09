"""
$(SIGNATURES)

Helper function for `convert_inter_html` that processes an extracted block given a latex context
`lxc` and returns the processed html that needs to be plugged in the final html.
"""
function convert_block(β::AbstractBlock, lxcontext::LxContext)::AbstractString
    # case for special characters / html entities
    β isa HTML_SPCH     && return ifelse(isempty(β.r), β.ss, β.r)

    # Return relevant interpolated string based on case
    βn = β.name
    βn ∈  MD_HEADER        && return convert_header(β)
    βn == :CODE_INLINE     && return md2html(β.ss; stripp=true, code=true)
    βn == :CODE_BLOCK_LANG && return convert_code_block(β.ss)
    βn == :CODE_BLOCK_IND  && return convert_indented_code_block(β.ss)
    βn == :CODE_BLOCK      && return md2html(β.ss; code=true)
    βn == :ESCAPE          && return chop(β.ss, head=3, tail=3)

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
const MATH_BLOCKS_PARENS = Dict{Symbol, Tuple{Int,Int,String,String}}(
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
    hk       = lowercase(string(β.name))
    title, _ = convert_md(content(β) * EOS; isrecursive=true, has_mddefs=false)
    # check if the header has appeared before
    rstitle  = refstring(title)
    level    = parse(Int, hk[2])
    occur    = (hv[3] for hv ∈ values(PAGE_HEADERS) if hv[2] == rstitle)
    occur    = isempty(occur) ? 0 : maximum(occur)
    rstitle  = ifelse(occur==0, rstitle, "$(rstitle)_$(occur+1)")
    # save in list of headers
    PAGE_HEADERS[length(PAGE_HEADERS)+1] = (title, rstitle, occur+1, level)
    # return the title
    return "<$hk><a id=\"$rstitle\" href=\"#$rstitle\">$title</a></$hk>"
end


"""
$(SIGNATURES)

Helper function for the code block case of `convert_block`.
"""
function convert_code_block(ss::SubString)::String
    m = match(r"```([a-z-]*)(\:[a-zA-Z\\\/-_\.]+)?\s*\n?((?:.|\n)*)```", ss)
    lang  = m.captures[1]
    rpath = m.captures[2]
    code  = m.captures[3]

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
    path = resolve_assets_rpath(rpath; canonical=true)

    endswith(path, ".jl") || (path *= ".jl")

    out_path, fname = splitdir(path)
    out_path = mkpath(joinpath(out_path, "output"))
    out_name = splitext(fname)[1] * ".out"
    out_path = joinpath(out_path, out_name)

    # > 1.b check whether the file already exists and if so compare content
    do_eval = !isfile(path) || read(path, String) != code || !isfile(out_path)

    if do_eval
        write(path, "# This file was generated by JuDoc, do not modify it. # hide\n", code)
        # step 2: execute the code while redirecting the output to file (note that
        # everything is ran in one big sequence of scripts so in particular if there
        # are 3 code blocks on the same page then the second and third one can use
        # whatever is defined or loaded in the first (it also has access to scope of
        # other pages but it's really not recommended to exploit that)
        open(out_path, "w") do outf
            redirect_stdout(outf)  do
                try
                    Main.include(path)
                catch e
                    print("There was an error running the code: $(e.error).")
                end
            end
        end
    end

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
    return html_code(code, "{{fill lang}}")
end
