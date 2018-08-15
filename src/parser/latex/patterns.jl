"""
    LX_NAME_PAT

Regex to find the name in a new command. For example:
    \\newcommand{\\com}[2]{def}
will give as first capture group `\\com`.
"""
const LX_NAME_PAT = r"^\s*(\\[a-zA-Z]+)\s*$"


"""
    LX_NARG_PAT

Regex to find the number of argument in a new command (if it is given). For
example:
    \\newcommand{\\com}[2]{def}
will give as second capture group `2`. If there are no number of arguments, the
second capturing group will be `nothing`.
"""
const LX_NARG_PAT = r"\s*(\[\s*(\d)\s*\])?\s*"
