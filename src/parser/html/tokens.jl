#=
NOTE: cf. note in tokens_md.jl

(no nesting)

* {{ ... }}
    * {{ fname param₁ param₂ }}
    * {{ fill vname }}
    * {{ insert fname }}
* [[ ... ]]
    * [[ if vname ... ]]                        --> simple if
    * [[ if vname ... ][ ... ]]                 --> if else
    * [[ if vname ...][ if vname2 ... ] ...]    --> if/elseif/else

=#

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
    '{' => [ isexactly("{{") => :H_BLOCK_OPEN    ],  # {{
    '}' => [ isexactly("}}") => :H_BLOCK_CLOSE   ],  # }}
    ) # end dict


"""
    HTML_EXTRACT

Dictionary to store opening tokens, their corresponding closing tokens and how
a block surrounded by such tokens should be referred to as (html context).
"""
const HTML_EXTRACT = Dict(
    # opening token    # closing token  # name of the block
    :H_BLOCK_OPEN   => :H_BLOCK_CLOSE  => :H_BLOCK,
)
