# XXX WIP
# also can read the specs in https://daringfireball.net/projects/markdown/syntax
# and see how to use them / extend them

# NOTE
# * quoting a block of code does not work well (need to check) the following doesn't work: (the >
# get captured in the code environment)
# > This is
# > a quote **with bold** and _emphasis_ and `code`
# > ```julia
# > x=5
# > x+1
# > ```

# ======
# GRUBER markdown (specified https://daringfireball.net/projects/markdown/syntax)
# -- horizontal rules; ***, *****, or -------------- will work but not * * * or - - -
# ======


"""
$SIGNATURES

Helps convert a markdown file used in a Jekyll setting to one that can be used in a JuDoc one.
It takes a string, applies standard fixes, and outputs a modified string that can be saved to file.
"""
function migrate_md(src::AbstractString)

    # Main ones:
    # --> code may be indented with quadruple space or 1 tab; a code block continues until
    # it reaches a line that is not indented (or the end of the article).

    # Minor ones:
    # --> find --- ... --- (header information) [Jekyll?]
    # --> people may use [...]: ... for link references interchangeably with [blah](link)
    # --> find `&...;` (html entities) and add a `\` in front and treat that as a `~~~.~~~`.


    return src
end

# function migrate(src::AbstractString, dest::String=""; format="jekyll")
#     isfile(src) || throw(ArgumentError("File $src not found."))
#
#     isempty(dest) && # ...
# end

# function migrate(folder)
