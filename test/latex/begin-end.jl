using Franklin, Test
const F = Franklin
# NOTE ongoing

include("../test_utils.jl")


has(t, s) = any(ti.name == s for ti in t)

mds = raw"""
    \newenvironment{aaa}[5]{pre}{post}
    \begin{aaa}
    bbb
    \end{aaa}
    """
tokens = F.find_tokens(mds, F.MD_TOKENS, F.MD_1C_TOKENS)

@test has(tokens, :LX_NEWENVIRONMENT)
@test has(tokens, :CAND_LX_BEGIN)
@test has(tokens, :CAND_LX_END)

blocks, tokens = F.find_all_ocblocks(tokens, F.MD_OCB2)

num_braces_orig = length(filter(b -> b.name == :LXB, blocks))

@test num_braces_orig == 5

F.find_lxenv_delims!(tokens, blocks)

@test has(tokens, :LX_BEGIN)
@test has(tokens, :LX_END)
@test !has(tokens, :CAND_LX_BEGIN)
@test !has(tokens, :CAND_LX_END)

num_braces_post = length(filter(b -> b.name == :LXB, blocks))

@test num_braces_post == 3

@test tokens[3].name == :LX_BEGIN
@test F.envname(tokens[3]) == "aaa"
@test tokens[6].name == :LX_END
@test F.envname(tokens[6]) == "aaa"

# ============= Part 2 : defs

lxdefs, tokens, braces, blocks = F.find_lxdefs(tokens, blocks)

@test lxdefs[1].name == "aaa"
@test lxdefs[1].narg == 5
@test lxdefs[1].def.first == "pre"
@test lxdefs[1].def.second == "post"

# TODO:
# - nesting
# - maths

s = raw"""
    \newenvironment{aaa}{pre}{post}
    \begin{aaa}
    bbb
    \end{aaa}""" |> fd2html
@test s // "pre bbb post"

s = raw"""
    \newenvironment{aaa}[1]{pre:#1}{post:#1}
    \begin{aaa}{00}
    bbb
    \end{aaa}""" |> fd2html
@test s // "pre: 00 bbb post: 00"

# redefinition
s = raw"""
    \newcommand{\abc}{123}
    \abc
    \newcommand{\abc}{321}
    \abc
    """ |> fd2html
@test s // "123\n321"

s = raw"""
    \newcommand{\abc}{123}
    \abc
    \newcommand{\abc}[1]{321:#1}
    \abc{aa}
    """ |> fd2html
@test s // "123\n321: aa"

s = raw"""
    \newenvironment{aaa}{pre}{post}
    \begin{aaa}
    bbb
    \end{aaa}

    ---

    \newenvironment{aaa}{PRE}{POST}
    \begin{aaa}
    ccc
    \end{aaa}
    """ |> fd2html
@test s // "pre bbb post\n<hr />\nPRE ccc POST"

s = raw"""
    \newenvironment{aaa}{pre}{post}
    \begin{aaa}
    bbb
    \end{aaa}

    ---

    \newenvironment{aaa}[1]{pre:#1}{post:#1}
    \begin{aaa}{00}
    bbb
    \end{aaa}
    """ |> fd2html
@test s // "pre bbb post\n<hr />\npre: 00 bbb post: 00"

# nesting

s = raw"""
    \newenvironment{aaa}{pre}{post}
    \newenvironment{bbb}[2]{abc:#1}{def:#2}
    \begin{aaa}
    A
    \begin{bbb}{00}{11}
    B
    \end{bbb}
    C
    \end{aaa}
    """ |> fd2html
@test s // "pre A abc: 00 B def: 11 C post"

# pre-existing

s = raw"""
    AA
    \begin{align}
    A &= B \\
    C &= D+E
    \end{align}
    BB
    """ |> fd2html
@test s // "<p>AA \\[\\begin{aligned}\nA &= B \\\\\nC &= D+E\n\\end{aligned}\\] BB</p>"
