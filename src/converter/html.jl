"""
    convert_html(hs)

Convert a judoc html string into a html string.
"""
function convert_html(hs)
    # Tokenize
    tokens = find_tokens(hs, HTML_TOKENS, HTML_1C_TOKENS)
    # Find hblocks
    hblocks, tokens = find_html_hblocks(hs, tokens)
    allblocks = JuDoc.get_html_allblocks(hblocks, endof(st))
end


"""
    convert_html__procblock(β)

Helper function to process an individual block.
"""
function convert_html__procblock(β::Block)
    # check if it is an if block?
    match(HBLOCK_IF, )


end
