"""
    MD_1C_TOKENS

Dictionary of single-char tokens for Markdown. Note that these characters are
exclusive, they cannot appear again in a larger token.
"""
const MD_1C_TOKENS = LittleDict{Char, Symbol}(
    '{'  => :LXB_OPEN,
    '}'  => :LXB_CLOSE,
    '\n' => :LINE_RETURN,
    )


"""
    MD_TOKENS_LX

Subset of `MD_1C_TOKENS` with only the latex tokens (for parsing what's in a math environment).
"""
const MD_1C_TOKENS_LX = LittleDict{Char, Symbol}(
    '{'  => :LXB_OPEN,
    '}'  => :LXB_CLOSE
    )


"""
    MD_TOKENS

Dictionary of tokens for Markdown. Note that for each, there may be several
possibilities to consider in which case the order is important: the first case
that works will be taken.
"""
const MD_TOKENS = LittleDict{Char, Vector{TokenFinder}}(
    '<'  => [ isexactly("<!--")  => :COMMENT_OPEN,     # <!-- ...
             ],
    '+'  => [ isexactly("+++", ('\n',)) => :MD_DEF_TOML,
             ],
    '-'  => [ isexactly("-->")   => :COMMENT_CLOSE,    #  ... -->
              incrlook(is_hr1)   => :HORIZONTAL_RULE,  # ---+
             ],
    '~'  => [ isexactly("~~~")   => :ESCAPE,           # ~~~  ... ~~~
             ],
    '['  => [ incrlook(is_footnote) => :FOOTNOTE_REF, # [^...](:)? defs will be separated after
             ],
    ']'  => [ isexactly("]: ") => :LINK_DEF,
             ],
    ':'  => [ incrlook(is_emoji) => :CAND_EMOJI,
             ],
    '\\' => [ # -- special characters, see `find_special_chars` in ocblocks
              isexactly("\\\\")       => :CHAR_LINEBREAK,   # --> <br/>
              isexactly("\\", (' ',)) => :CHAR_BACKSPACE,   # --> &#92;
              isexactly("\\*")        => :CHAR_ASTERISK,    # --> &#42;
              isexactly("\\_")        => :CHAR_UNDERSCORE,  # --> &#95;
              isexactly("\\`")        => :CHAR_BACKTICK,    # --> &#96;
              isexactly("\\@")        => :CHAR_ATSIGN,      # --> &#64;
              # -- maths
              isexactly("\\{")        => :INACTIVE,         # See note [^1]
              isexactly("\\}")        => :INACTIVE,         # See note [^1]
              isexactly("\\\$")       => :INACTIVE,         # See note [^1]
              isexactly("\\[")        => :MATH_C_OPEN,      # \[ ...
              isexactly("\\]")        => :MATH_C_CLOSE,     #    ... \]
              # -- latex
              isexactly("\\newenvironment", ('{',)) => :LX_NEWENVIRONMENT,
              isexactly("\\newcommand", ('{',))     => :LX_NEWCOMMAND,
              isexactly("\\begin", ('{',)) => :CAND_LX_BEGIN,
              isexactly("\\end", ('{',))   => :CAND_LX_END,
              incrlook((_, c) -> α(c))     => :LX_COMMAND,  # \command⎵*
             ],
    '@'  => [ isexactly("@def", (' ',))   => :MD_DEF_OPEN,    # @def var = ...
              isexactly("@@", SPACE_CHAR) => :DIV_CLOSE,      # @@⎵*
              incrlook(is_div_open)       => :DIV_OPEN,       # @@dname
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
              isexactly("\$\$")              => :MATH_B,  # $$⎵*
             ],
    '_'  => [ isexactly("_\$>_") => :MATH_I_OPEN,  # internal use when resolving a latex command
              isexactly("_\$<_") => :MATH_I_CLOSE, # within mathenv (e.g. \R <> \mathbb R)
              incrlook(is_hr2)   => :HORIZONTAL_RULE,
             ],
    '`'  => [ isexactly("`",  ('`',), false)  => :CODE_SINGLE, # `⎵
              isexactly("``", ('`',), false)  => :CODE_DOUBLE, # ``⎵*
              # 3+ can be named
              isexactly("```",   SPACE_CHAR) => :CODE_TRIPLE,  # ```⎵*
              isexactly("```!",  SPACE_CHAR) => :CODE_TRIPLE!, # ```!⎵*
              isexactly("```>",  SPACE_CHAR) => :CODE_REPL,    # ```>⎵*
              is_language(3)                 => :CODE_LANG3,   # ```lang*
              isexactly("````",  SPACE_CHAR) => :CODE_QUAD,    # ````⎵*
              is_language(4)                 => :CODE_LANG4,   # ````lang*
              isexactly("`````", SPACE_CHAR) => :CODE_PENTA,   # `````⎵*
              is_language(5)                 => :CODE_LANG5,   # `````lang*
             ],
    '*'  => [ incrlook(is_hr3) => :HORIZONTAL_RULE,
             ]
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
    L_RETURNS

Convenience tuple containing the name for standard line returns and line
returns followed by an indentation (either a quadruple space or a tab).
"""
const L_RETURNS = (:LINE_RETURN, :LR_INDENT, :EOS)


"""
    MD_OCB

List of Open-Close Blocks whose content should be deactivated (any token within
their span should be marked as inactive) until further processing.
The keys are identifier for the type of block, the value is a pair with the
opening and closing tokens followed by a boolean indicating whether the content
of the block should be reprocessed.
The only `OCBlock` not in this dictionary is the brace block since it should
not deactivate its content which is needed to find latex definitions
(see parser/markdown/find_blocks/find_lxdefs).
"""
const MD_OCB = [
    # name                    opening token   closing token(s)
    # ---------------------------------------------------------------------
    OCProto(:COMMENT,         :COMMENT_OPEN, (:COMMENT_CLOSE,)),
    OCProto(:MD_DEF_BLOCK,    :MD_DEF_TOML,  (:MD_DEF_TOML,)  ),
    OCProto(:CODE_BLOCK_LANG, :CODE_LANG3,   (:CODE_TRIPLE,)  ),
    OCProto(:CODE_BLOCK_LANG, :CODE_LANG4,   (:CODE_QUAD,)    ),
    OCProto(:CODE_BLOCK_LANG, :CODE_LANG5,   (:CODE_PENTA,)   ),
    OCProto(:CODE_BLOCK!,     :CODE_TRIPLE!, (:CODE_TRIPLE,)  ),
    OCProto(:CODE_REPL,       :CODE_REPL,    (:CODE_TRIPLE,)  ),
    OCProto(:CODE_BLOCK,      :CODE_TRIPLE,  (:CODE_TRIPLE,)  ),
    OCProto(:CODE_BLOCK,      :CODE_QUAD,    (:CODE_QUAD,)    ),
    OCProto(:CODE_BLOCK,      :CODE_PENTA,   (:CODE_PENTA,)   ),
    OCProto(:CODE_INLINE,     :CODE_DOUBLE,  (:CODE_DOUBLE,)  ),
    OCProto(:CODE_INLINE,     :CODE_SINGLE,  (:CODE_SINGLE,)  ),
    OCProto(:MD_DEF,          :MD_DEF_OPEN,  L_RETURNS        ), # [^4]
    OCProto(:CODE_BLOCK_IND,  :LR_INDENT,    (:LINE_RETURN,)  ),
    OCProto(:ESCAPE,          :ESCAPE,       (:ESCAPE,)       ),
    OCProto(:FOOTNOTE_DEF,    :FOOTNOTE_DEF, L_RETURNS        ),
    OCProto(:LINK_DEF,        :LINK_DEF,     L_RETURNS        ),
    # ------------------------------------------------------------------
    OCProto(:H1,              :H1_OPEN,      L_RETURNS), # see [^3]
    OCProto(:H2,              :H2_OPEN,      L_RETURNS),
    OCProto(:H3,              :H3_OPEN,      L_RETURNS),
    OCProto(:H4,              :H4_OPEN,      L_RETURNS),
    OCProto(:H5,              :H5_OPEN,      L_RETURNS),
    OCProto(:H6,              :H6_OPEN,      L_RETURNS)
    ]
# the split is due to double brace blocks being allowed in markdown
const MD_OCB2 = [
    OCProto(:LXB,             :LXB_OPEN,     (:LXB_CLOSE,), nestable=true),
    OCProto(:DIV,             :DIV_OPEN,     (:DIV_CLOSE,), nestable=true),
    ]
#= NOTE:
* [3] a header can be closed by either a line return or an end of string (for
instance in the case where a user defines a latex command like so:
\newcommand{\section}{# blah} (no line return).)
* [4] MD_DEF take precedence over CODE_IND, note that if you have an indented
* block with @def in it, things may go bad.
* ordering matters!
=#


"""
    MD_HEADER

All header symbols.
"""
const MD_HEADER = (:H1, :H2, :H3, :H4, :H5, :H6)


"""
    MD_HEADER_OPEN

All header symbols (opening).
"""
const MD_HEADER_OPEN = (:H1_OPEN, :H2_OPEN, :H3_OPEN, :H4_OPEN, :H5_OPEN, :H6_OPEN)


"""
    MD_OCB_ESC

Blocks that will be escaped (tokens in their span will be ignored on the
current parsing round).
"""
const MD_OCB_ESC = [e.name for e ∈ MD_OCB if !e.nest]


"""
    MD_OCB_MATH

Same concept as `MD_OCB` but for math blocks, they can't be nested. Separating
them from the other dictionary makes their processing easier.
Dev note: order does not matter.
"""
const MD_OCB_MATH = [
    OCProto(:MATH_A,     :MATH_A,          (:MATH_A,)          ),
    OCProto(:MATH_B,     :MATH_B,          (:MATH_B,)          ),
    OCProto(:MATH_C,     :MATH_C_OPEN,     (:MATH_C_CLOSE,)    ),
    OCProto(:MATH_I,     :MATH_I_OPEN,     (:MATH_I_CLOSE,)    ),
    ]

const MD_OCB_LXB = [e for e in MD_OCB2 if e.name == :LXB]

"""
    MD_OCB_ALL

Combination of all `MD_OCB` in order.
DEV: only really used in tests.
"""
const MD_OCB_ALL = vcat(MD_OCB, MD_OCB2, MD_OCB_MATH)

"""
    MD_OCB_IGNORE

List of names of blocks that will need to be dropped at compile time.
"""
const MD_OCB_IGNORE = (:COMMENT, :MD_DEF)

"""
    MATH_DISPLAY_BLOCKS_NAMES

List of names of maths environments (display mode).
"""
const MATH_DISPLAY_BLOCKS_NAMES = collect(e.name for e ∈ MD_OCB_MATH if e.name != :MATH_A)

"""
    MATH_BLOCKS_NAMES

List of names of all maths environments.
"""
const MATH_BLOCKS_NAMES = tuple(:MATH_A, MATH_DISPLAY_BLOCKS_NAMES...)

"""
CODE_BLOCKS_NAMES

List of names of code blocks environments.
"""
const CODE_BLOCKS_NAMES = (
    :CODE_BLOCK_LANG,
    :CODE_BLOCK,
    :CODE_BLOCK!,
    :CODE_REPL,
    :CODE_BLOCK_IND
    )

"""
    MD_CLOSEP

Blocks which, upon insertion, should close any open paragraph.
Order doesn't matter.
"""
const MD_CLOSEP = [MD_HEADER..., :DIV, CODE_BLOCKS_NAMES..., MATH_DISPLAY_BLOCKS_NAMES...]

"""
    MD_OCB_NO_INNER

List of names of blocks which will deactivate any block contained within them
as their content will be reprocessed later on.
See [`find_all_ocblocks`](@ref).
"""
const MD_OCB_NO_INNER = vcat(MD_OCB_ESC, MATH_BLOCKS_NAMES, :LXB, MD_HEADER)
