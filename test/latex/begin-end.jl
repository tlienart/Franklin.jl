using Test
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
