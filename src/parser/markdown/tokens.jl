#=
NOTE: TOKENS must be single-char characters, for safety, that means they are
composed of chars before code-point 80. So not things like ∀ or ∃ etc.
=#

"""
    MD_1C_TOKENS

Dictionary of single-char tokens for Markdown. Note that these characters are
exclusive, they cannot appear again in a larger token.
"""
const MD_1C_TOKENS = Dict{Char, Symbol}(
    '{'  => :LX_BRACE_OPEN,
    '}'  => :LX_BRACE_CLOSE,
    '\n' => :LINE_RETURN)


"""
    MD_TOKENS_LX

Subset of `MD_1C_TOKENS` with only the latex tokens (for parsing what's in a math environment).
"""
const MD_1C_TOKENS_LX = Dict{Char, Symbol}(
    '{'  => :LX_BRACE_OPEN,
    '}'  => :LX_BRACE_CLOSE)


"""
    MD_TOKENS

Dictionary of tokens for Markdown. Note that for each, there may be several
possibilities to consider in which case the order is important: the first
case that works will be taken.
"""
const MD_TOKENS = Dict{Char, Vector{Pair{Tuple{Int, Bool, Function}, Symbol}}}(
    '<' => [ isexactly("<!--") => :COMMENT_OPEN ],   # <!-- ...
    '-' => [ isexactly("-->")  => :COMMENT_CLOSE ],  #      ... -->
    '~' => [ isexactly("~~~")  => :ESCAPE ],         # ~~~  ... ~~~
    '\\' => [
        isexactly("\\{")  => :INACTIVE,              # See note [^1]
        isexactly("\\}")  => :INACTIVE,              # See note [^1]
        isexactly("\\\$") => :INACTIVE,              # See note [^1]
        isexactly("\\[")  => :MATH_C_OPEN,           # \[ ...
        isexactly("\\]")  => :MATH_C_CLOSE,          #    ... \]
        isexactly("\\begin{align}")    => :MATH_ALIGN_OPEN,
        isexactly("\\end{align}")      => :MATH_ALIGN_CLOSE,
        isexactly("\\begin{eqnarray}") => :MATH_EQA_OPEN,
        isexactly("\\end{eqnarray}")   => :MATH_EQA_CLOSE,
        isexactly("\\newcommand")      => :LX_NEWCOMMAND,
        incrlook((_, c) -> α(c))       => :LX_COMMAND ], # \command⎵*
    '@' => [
        isexactly("@def", [' ']) => :MD_DEF_OPEN,    # @def var = ...
        isexactly("@@", SPACER)  => :DIV_CLOSE,      # @@⎵*
        incrlook((i, c) ->
            ifelse(i==1, c=='@', α(c, ['-']))) => :DIV_OPEN ], # @@dname
    '$' => [
        isexactly("\$", ['$'], false) => :MATH_A,    # $⎵*
        isexactly("\$\$") => :MATH_B,                # $$⎵*
    ],
    '_' => [
        isexactly("_\$>_") => :MATH_I_OPEN,
        isexactly("_\$<_") => :MATH_I_CLOSE,
    ],
    '`' => [
        isexactly("`", ['`'], false) => :CODE_SINGLE,             # `⎵*
        isexactly("```", SPACER) => :CODE,                        # ```⎵*
        incrlook((i, c) -> i∈[1,2] ? c=='`' : α(c)) => :CODE_L ], # ``lang*
    ) # end dict
#= NOTE
[1] capturing \{ here will force the head to move after it thereby not
marking it as a potential open brace, same for the close brace.
[2] check if these are still useful. =#


"""
    MD_TOKENS_LX

Subset of `MD_TOKENS` with only the latex tokens (for parsing what's in a math
environment).
"""
const MD_TOKENS_LX = Dict{Char, Vector{Pair{Tuple{Int, Bool, Function}, Symbol}}}(
    '\\' => [
        isexactly("\\{")         => :INACTIVE,
        isexactly("\\}")         => :INACTIVE,
        incrlook((_, c) -> α(c)) => :LX_COMMAND ])


#=
    EXTRACT BLOCKS
=#

# Blocks that will be extracted and that will NOT interact with latex
# (if any \... is present in them, it will stay like that and not be resolved)
"""
    MD_EXTRACT

Dictionary to store opening tokens, their corresponding closing tokens and how
a block surrounded by such tokens should be referred to as (md context).
"""
const MD_EXTRACT = Dict(
    # opening token  # closing token   # name of the block
    :COMMENT_OPEN => :COMMENT_CLOSE => :COMMENT,
    :ESCAPE       => :ESCAPE        => :ESCAPE,
    :MD_DEF_OPEN  => :LINE_RETURN   => :MD_DEF,         # See note [^3]
    :CODE_SINGLE  => :CODE_SINGLE   => :CODE,
    :CODE_L       => :CODE          => :CODE,
    :CODE         => :CODE          => :CODE,
    ) # end dict
#= NOTE
[3] an `MD_DEF` goes from an `@def` to the next `\n` so no multiple line def
are allowed =#


#=
    MATH BLOCKS
=#

# Math blocks, those can potentially interact with latex.
# (if any \... is present in them, jd will try to resolve it)
"""
    MD_MATHS

Dictionary to store opening tokens, their corresponding closing tokens and how
a block surrounded by such tokens should be referred to as. Additionally all
these blocks should be considered as maths environments.
"""
const MD_MATHS = Dict(
    :MATH_A          => :MATH_A           => :MATH_A,
    :MATH_B          => :MATH_B           => :MATH_B,
    :MATH_C_OPEN     => :MATH_C_CLOSE     => :MATH_C,
    :MATH_I_OPEN     => :MATH_I_CLOSE     => :MATH_I,
    :MATH_ALIGN_OPEN => :MATH_ALIGN_CLOSE => :MATH_ALIGN,
    :MATH_EQA_OPEN   => :MATH_EQA_CLOSE   => :MATH_EQA,
    ) # end dict


"""
    MD_MATH_NAMES

List of names of maths environments.
"""
const MD_MATHS_NAMES = [η for (_, (⎵, η)) ∈ MD_MATHS]


"""
    mathenv(s)

Convenience function to denote a string as being in a math context in a
recursive parsing situation. These blocks will be processed as math blocks
but without adding KaTeX elements to it given that they are part of a larger
context that already has KaTeX elements.
"""
mathenv(s) = "_\$>_" * s * "_\$<_"
