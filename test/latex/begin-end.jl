using Franklin, Test
const F = Franklin
# NOTE ongoing

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

F.form_lxenv_delims!(tokens, blocks)

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
# XXX test this a fair bit (newenv def, and lxenv formation)
# XXX remaining -- resolve command

lxdefs, tokens, braces, blocks = F.find_lxdefs(tokens, blocks)

@test lxdefs[1].name == "aaa"
@test lxdefs[1].narg == 5
@test lxdefs[1].def.first == "pre"
@test lxdefs[1].def.second == "post"

# ==============


envs, tokens = F.form_lxenvs(tokens)

@test length(envs) == 1
@test envs[1].name == :LX_ENV
@test F.envname(envs[1]) == "aaa"
@test !has(tokens, :LX_BEGIN)
@test !has(tokens, :LX_END)


# TODO:
# - nesting
# - maths
