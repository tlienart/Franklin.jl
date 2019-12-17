#
# Parsing related
#
"""An OCBlock was not parsed properly (e.g. the closing token was not found)."""
struct OCBlockError <: Exception
    m::String
    c::String
end

function Base.showerror(io::IO, be::OCBlockError)
    println(io, be.m)
    print(io, be.c)
end

"""A `\\newcommand` was not parsed properly."""
struct LxDefError <: Exception
    m::String
end

"""A latex command was found but could not be processed properly."""
struct LxComError <: Exception
    m::String
end

"""A math block name failed to parse."""
struct MathBlockError <: Exception
    m::String
end

#
# HTML related
#

"""An HTML block (e.g. [`HCond`](@see)) was erroneous."""
struct HTMLBlockError <: Exception
    m::String
end

"""An HTML function (e.g. `{{fill ...}}`) failed."""
struct HTMLFunctionError <: Exception
    m::String
end
