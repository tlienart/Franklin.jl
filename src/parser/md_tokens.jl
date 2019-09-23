"""
MD_1C_TOKENS

Dictionary of single-char tokens for Markdown. Note that these characters are exclusive, they
cannot appear again in a larger token.
"""
const MD_1C_TOKENS = Dict{Char, Symbol}(
    '{'  => :LXB_OPEN,
    '}'  => :LXB_CLOSE,
    '\n' => :LINE_RETURN,
    EOS  => :EOS,
    )


"""
MD_TOKENS_LX

Subset of `MD_1C_TOKENS` with only the latex tokens (for parsing what's in a math environment).
"""
const MD_1C_TOKENS_LX = Dict{Char, Symbol}(
    '{'  => :LXB_OPEN,
    '}'  => :LXB_CLOSE
    )


"""
MD_TOKENS

Dictionary of tokens for Markdown. Note that for each, there may be several possibilities to
consider in which case the order is important: the first case that works will be taken.
"""
const MD_TOKENS = Dict{Char, Vector{TokenFinder}}(
    '<'  => [ isexactly("<!--") => :COMMENT_OPEN,     # <!-- ...
             ],
    '-'  => [ isexactly("-->")  => :COMMENT_CLOSE,    #      ... -->
             ],
    '~'  => [ isexactly("~~~")  => :ESCAPE,           # ~~~  ... ~~~
             ],
    '['  => [ incrlook(is_footnote) => :FOOTNOTE_REF,    # [^...](:)? defs will be separated after
             ],
    ']'  => [ isexactly("]: ") => :LINK_DEF,
             ],
    '\\' => [ isexactly("\\{")        => :INACTIVE,         # See note [^1]
              isexactly("\\}")        => :INACTIVE,         # See note [^1]
              isexactly("\\\$")       => :INACTIVE,         # See note [^1]
              isexactly("\\[")        => :MATH_C_OPEN,      # \[ ...
              isexactly("\\]")        => :MATH_C_CLOSE,     #    ... \]
              isexactly("\\begin{align}")    => :MATH_ALIGN_OPEN,
              isexactly("\\end{align}")      => :MATH_ALIGN_CLOSE,
              isexactly("\\begin{equation}") => :MATH_D_OPEN,
              isexactly("\\end{equation}")   => :MATH_D_CLOSE,
              isexactly("\\begin{eqnarray}") => :MATH_EQA_OPEN,
              isexactly("\\end{eqnarray}")   => :MATH_EQA_CLOSE,
              isexactly("\\newcommand")      => :LX_NEWCOMMAND,
              isexactly("\\\\")              => :CHAR_LINEBREAK, # will be replaced by <br/>
              isexactly("\\", (' ',))        => :CHAR_BACKSPACE, # will be replaced by &#92;
              isexactly("\\`")               => :CHAR_BACKTICK,  # will be replaced by &#96;
              incrlook((_, c) -> α(c))       => :LX_COMMAND,     # \command⎵*
             ],
    '@'  => [ isexactly("@def", (' ',)) => :MD_DEF_OPEN,  # @def var = ...
              isexactly("@@", SPACER)   => :DIV_CLOSE,    # @@⎵*
              incrlook(is_div_open)     => :DIV_OPEN, # @@dname
             ],
    '#'  => [ isexactly("#",      (' ',)) => :H1_OPEN, # see note [^2]
              isexactly("##",     (' ',)) => :H2_OPEN,
              isexactly("###",    (' ',)) => :H3_OPEN,
              isexactly("####",   (' ',)) => :H4_OPEN,
              isexactly("#####",  (' ',)) => :H5_OPEN,
              isexactly("######", (' ',)) => :H6_OPEN,
             ],
    '&'  => [ incrlook(is_html_entity) => :CHAR_HTML_ENTITY,
             ],
    '$'  => [ isexactly("\$", ('$',), false) => :MATH_A,  # $⎵*
              isexactly("\$\$") => :MATH_B,              # $$⎵*
             ],
    '_'  => [ isexactly("_\$>_") => :MATH_I_OPEN,   # internal use when resolving a latex command
              isexactly("_\$<_") => :MATH_I_CLOSE,  # within mathenv (e.g. \R <> \mathbb R)
             ],
    '`'  => [ isexactly("`", ('`',), false) => :CODE_SINGLE, # `⎵
              isexactly("``",('`',), false) => :CODE_DOUBLE, # ``⎵*
              isexactly("```", SPACER)      => :CODE_TRIPLE, # ```⎵*
              incrlook(is_language)         => :CODE_LANG,   # ```lang*
             ],
    ) # end dict
#= NOTE
[1] capturing \{ here will force the head to move after it thereby not
marking it as a potential open brace, same for the close brace.
[2] similar to @def except that it must be at the start of the line. =#


"""
MD_TOKENS_LX

Subset of `MD_TOKENS` with only the latex tokens (for parsing what's in a math environment).
"""
const MD_TOKENS_LX = Dict{Char, Vector{TokenFinder}}(
    '\\' => [
        isexactly("\\{")         => :INACTIVE,
        isexactly("\\}")         => :INACTIVE,
        incrlook((_, c) -> α(c)) => :LX_COMMAND ]
    )


"""
MD_DEF_PAT

Regex to match an assignment of the form
    @def var = value
The first group captures the name (`var`), the second the assignment (`value`).
"""
const MD_DEF_PAT = r"@def\s+(\S+)\s*?=\s*?(\S.*)"


"""
L_RETURNS

Convenience tuple containing the name for standard line returns and line returns followed by an
indentation (either a quadruple space or a tab).
"""
const L_RETURNS = (:LINE_RETURN, :LR_INDENT)

"""
MD_OCB

Dictionary of Open-Close Blocks whose content should be deactivated (any token within their span
should be marked as inactive) until further processing.
The keys are identifier for the type of block, the value is a pair with the opening and closing
tokens followed by a boolean indicating whether the content of the block should be reprocessed.
The only `OCBlock` not in this dictionary is the brace block since it should not deactivate its
content which is needed to find latex definitions (see parser/markdown/find_blocks/find_md_lxdefs).
"""
const MD_OCB = [
    # name                    opening token   closing token(s)     nestable
    # ---------------------------------------------------------------------
    OCProto(:COMMENT,         :COMMENT_OPEN, (:COMMENT_CLOSE,), false),
    OCProto(:CODE_BLOCK_LANG, :CODE_LANG,    (:CODE_TRIPLE,),   false),
    OCProto(:CODE_BLOCK,      :CODE_TRIPLE,  (:CODE_TRIPLE,),   false),
    OCProto(:CODE_BLOCK_IND,  :LR_INDENT,    (:LINE_RETURN,),   false),
    OCProto(:CODE_INLINE,     :CODE_DOUBLE,  (:CODE_DOUBLE,),   false),
    OCProto(:CODE_INLINE,     :CODE_SINGLE,  (:CODE_SINGLE,),   false),
    OCProto(:ESCAPE,          :ESCAPE,       (:ESCAPE,),        false),
    OCProto(:FOOTNOTE_DEF,    :FOOTNOTE_DEF, (:LINE_RETURN,),   false),
    OCProto(:LINK_DEF,        :LINK_DEF,     (:LINE_RETURN,),   false),
    # ------------------------------------------------------------------
    OCProto(:H1,              :H1_OPEN,      (L_RETURNS..., :EOS), false), # see [^3]
    OCProto(:H2,              :H2_OPEN,      (L_RETURNS..., :EOS), false),
    OCProto(:H3,              :H3_OPEN,      (L_RETURNS..., :EOS), false),
    OCProto(:H4,              :H4_OPEN,      (L_RETURNS..., :EOS), false),
    OCProto(:H5,              :H5_OPEN,      (L_RETURNS..., :EOS), false),
    OCProto(:H6,              :H6_OPEN,      (L_RETURNS..., :EOS), false),
    # ------------------------------------------------------------------
    OCProto(:MD_DEF,          :MD_DEF_OPEN,  (L_RETURNS..., :EOS), false), # see [^4]
    OCProto(:LXB,             :LXB_OPEN,     (:LXB_CLOSE,),        true ),
    OCProto(:DIV,             :DIV_OPEN,     (:DIV_CLOSE,),        true ),
    ]
#= NOTE:
* [3] a header can be closed by either a line return or an end of string (for instance in the case
where a user defines a latex command like so: \newcommand{\section}{# blah} (no line return).)
* [4] an `MD_DEF` goes from an `@def` to the next `\n` so no multiple-line
def are allowed.
* ordering matters!
=#

"""
MD_HEADER

All header symbols.
"""
const MD_HEADER = (:H1, :H2, :H3, :H4, :H5, :H6)


"""
MD_OCB_ESC

Blocks that will be escaped (their content will not be further processed).
Corresponds to the "non-reprocess" elements of `MD_OCB`.
"""
const MD_OCB_ESC = [e.name for e ∈ MD_OCB if !e.nest]


"""
MD_OCB_MATH

Same concept as `MD_OCB` but for math blocks, they can't be nested. Separating them from the other
dictionary makes their processing easier.
Dev note: order does not matter.
"""
const MD_OCB_MATH = [
    OCProto(:MATH_A,     :MATH_A,          (:MATH_A,),           false),
    OCProto(:MATH_B,     :MATH_B,          (:MATH_B,),           false),
    OCProto(:MATH_C,     :MATH_C_OPEN,     (:MATH_C_CLOSE,),     false),
    OCProto(:MATH_C,     :MATH_D_OPEN,     (:MATH_D_CLOSE,),     false),
    OCProto(:MATH_I,     :MATH_I_OPEN,     (:MATH_I_CLOSE,),     false),
    OCProto(:MATH_ALIGN, :MATH_ALIGN_OPEN, (:MATH_ALIGN_CLOSE,), false),
    OCProto(:MATH_EQA,   :MATH_EQA_OPEN,   (:MATH_EQA_CLOSE,),   false),
    ]

"""
MD_OCB_ALL

Combination of all `MD_OCB` in order.
"""
const MD_OCB_ALL = vcat(MD_OCB, MD_OCB_MATH) # order matters


"""
MD_OCB_IGNORE

List of names of blocks that will need to be dropped at compile time.
"""
const MD_OCB_IGNORE = [:COMMENT, :MD_DEF]


"""
MATH_BLOCKS_NAMES

List of names of maths environments.
"""
const MATH_BLOCKS_NAMES = [e.name for e ∈ MD_OCB_MATH]
