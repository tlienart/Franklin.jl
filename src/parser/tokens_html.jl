"""
    HTML_1C_TOKENS

Dictionary of single-char tokens for HTML. Note that these characters are
exclusive, they cannot appear again in a larger token.
"""
const HTML_1C_TOKENS = Dict{Char, Symbol}()


"""
    HTML_TOKENS

Dictionary of tokens for HTML. Note that for each, there may be several
possibilities to consider in which case the order is important: the first
case that works will be taken.
"""
const HTML_TOKENS = Dict{Char, Vector{Pair{Tuple{Int, Bool, Function}, Symbol}}}(
    '<' => [ isexactly("<!--") => :COMMENT_OPEN  ],  # <!-- ...
    '-' => [ isexactly("-->")  => :COMMENT_CLOSE ],  #      ... -->
    '{' => [ isexactly("{{")   => :H_BLOCK_OPEN  ],  # {{
    '}' => [ isexactly("}}")   => :H_BLOCK_CLOSE ],  # }}
    ) # end dict


"""
    HTML_EXTRACT

Dictionary to store opening tokens, their corresponding closing tokens and how
a block surrounded by such tokens should be referred to as (html context).
"""
const HTML_EXTRACT = Dict(
    # opening token  # closing token  # name of the block
    :H_BLOCK_OPEN => :H_BLOCK_CLOSE  => :H_BLOCK,
)


"""
    HTML_COMMENTS

Same as `HTML_EXTRACT` but for blocks that need to be escaped (primarily comments), so that they can get escaped.
"""
const HTML_ESCAPE = Dict(
    # opening token  # closing token   # name of the block
    :COMMENT_OPEN => :COMMENT_CLOSE => :COMMENT,
)


const HTML_OCB = [
    # name        opening token    closing token     nestable
    # ------------------------------------------------------------
    :COMMENT => ((:COMMENT_OPEN => :COMMENT_CLOSE), false),
    :H_BLOCK => ((:H_BLOCK_OPEN => :H_BLOCK_CLOSE), true)
]
