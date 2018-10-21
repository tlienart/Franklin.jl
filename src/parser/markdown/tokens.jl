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
    '{'  => :LXB_OPEN,
    '}'  => :LXB_CLOSE,
    '\n' => :LINE_RETURN)


"""
    MD_TOKENS_LX

Subset of `MD_1C_TOKENS` with only the latex tokens (for parsing what's in a math environment).
"""
const MD_1C_TOKENS_LX = Dict{Char, Symbol}(
    '{'  => :LXB_OPEN,
    '}'  => :LXB_CLOSE)


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
    :CODE_SINGLE  => :CODE_SINGLE   => :CODE_INLINE,
    :CODE_L       => :CODE          => :CODE_BLOCK,
    :CODE         => :CODE          => :CODE_BLOCK,
    ) # end dict
#= NOTE
[3] an `MD_DEF` goes from an `@def` to the next `\n` so no multiple line def
are allowed =#


"""
    MD_OCBLOCKS

Dictionary of open-close blocks whose content should be deactivated (any token
within their span should be marked as inactive) until further processing.
The keys are identifier for the type of block, the value is a pair with the
opening and closing tokens followed by a boolean indicating whether the block
is nestable or not.
The only `OCBlock` not in this dictionary is the brace block since it should
not deactivate its content which is needed to find latex definitions (see
parser/markdown/find_blocks/find_md_lxdefs).
"""
const MD_OCBLOCKS = Dict(
    # name            opening token    closing token     nestable
    :DIV          => ((:DIV_OPEN     => :DIV_CLOSE    ), true),
    :COMMENT      => ((:COMMENT_OPEN => :COMMENT_CLOSE), false),
    :ESCAPE       => ((:ESCAPE       => :ESCAPE       ), false),
    :MD_DEF       => ((:MD_DEF_OPEN  => :LINE_RETURN  ), false), # see [^3]
    :CODE_INLINE  => ((:CODE_SINGLE  => :CODE_SINGLE  ), false),
    :CODE_BLOCK_L => ((:CODE_L       => :CODE         ), false),
    :CODE_BLOCK   => ((:CODE         => :CODE         ), false)
)
#= NOTE:
    [3] an `MD_DEF` goes from an `@def` to the next `\n` so no multiple-line
    def are allowed.
=#


"""
    MC_OCBLOCKS_MATHS

Same concept as `MD_OCBLOCKS` but for math blocks, they can't be nested.
Separating them from the other dictionary makes their processing easier.
"""
const MD_OCBLOCKS_MATHS = Dict(
    :MATH_A     => (:MATH_A          => :MATH_A          ),
    :MATH_B     => (:MATH_B          => :MATH_B          ),
    :MATH_C     => (:MATH_C_OPEN     => :MATH_C_CLOSE    ),
    :MATH_I     => (:MATH_I_OPEN     => :MATH_I_CLOSE    ),
    :MATH_ALIGN => (:MATH_ALIGN_OPEN => :MATH_ALIGN_CLOSE),
    :MATH_EQA   => (:MATH_EQA_OPEN   => :MATH_EQA_CLOSE  ),
)


"""
    MD_MATH_NAMES

List of names of maths environments.
"""
const MD_MATHS_NAMES = keys(MD_OCBLOCKS_MATHS)


for name ∈ MD_MATHS_NAMES
    MD_OCBLOCKS[name] = (MD_OCBLOCKS_MATHS[name], false)
end


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
    mathenv(s)

Convenience function to denote a string as being in a math context in a
recursive parsing situation. These blocks will be processed as math blocks
but without adding KaTeX elements to it given that they are part of a larger
context that already has KaTeX elements.
"""
mathenv(s) = "_\$>_" * s * "_\$<_"
