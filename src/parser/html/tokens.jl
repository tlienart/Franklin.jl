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
    '{' => [ isexactly("{{") => :FUN_OPEN    ],  # {{
    '}' => [ isexactly("}}") => :FUN_CLOSE   ],  # }}
    '[' => [ isexactly("[[") => :CTRL_OPEN   ],  # [[
    ']' => [ isexactly("]]") => :CTRL_CLOSE  ],  # ]]
    ']' => [ isexactly("][") => :CTRL_CLOPEN ],  # ][
    ) # end dict
