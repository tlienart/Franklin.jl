# This file was generated, do not modify it. # hide
#hideall
using PyCall
lines = replace("""import numpy as np
np.random.seed(2)
x = np.random.randn(5)
r = np.linalg.norm(x) / len(x)
np.round(r, 2)""", r"(^|\n)([^\n]+)\n?$" => s"\1res = \2")
py"""
$$lines
"""
println(py"res")