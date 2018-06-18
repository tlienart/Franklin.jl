"""
    MDBlock

A `MDBlock` object contains the information required to find a specific block in
a markdown string as well as how to replace this block.

* `fpat`: pattern describing how to find the block in the string
* `rpat`: pattern describing how to replace the block

When the opening and closing tokens are symetric, we need to keep track of how
long the token is (`sym_offset`).
"""
struct MDBlock
    fpat::Tuple{String, String} # pattern to find the block
    rpat::Tuple{String, String} # pattern to replace the block
    sym_offset::Int # offset for symmetric patterns (see symmetric handling)
end
# Simplified constructor: default offset is 0 (asymmetric case)
MDBlock(fpat, rpat) = MDBlock(fpat, rpat, 0)

"""
    regex(mdb)

Take a `MDBlock` and return the corresponding regex to find it and match the
content of the block.
"""
regex(mdb::MDBlock) = Regex(mdb.fpat[1] * "((.|\\n)*?)" * mdb.fpat[2])


"""
    mdb(elem)

Allow to use a `MDBlock` instance `mdb` to be used as a function on an element
`elem` to return the corresponding replacement string.
"""
(mdb::MDBlock)(elem) = mdb.rpat[1] * elem * mdb.rpat[2]
