abstract type JuDocException <: Exception end

#
# Parsing related
#

"""An OCBlock was not parsed properly (e.g. the closing token was not found)."""
struct OCBlockError <: JuDocException
    m::String
    c::String
end

function Base.showerror(io::IO, be::OCBlockError)
    println(io, be.m)
    print(io, be.c)
end

"""A `\\newcommand` was not parsed properly."""
struct LxDefError <: JuDocException
    m::String
end

"""A latex command was found but could not be processed properly."""
struct LxComError <: JuDocException
    m::String
end

"""A math block name failed to parse."""
struct MathBlockError <: JuDocException
    m::String
end

#
# HTML related
#

"""An HTML block (e.g. [`HCond`](@see)) was erroneous."""
struct HTMLBlockError <: JuDocException
    m::String
end

"""An HTML function (e.g. `{{fill ...}}`) failed."""
struct HTMLFunctionError <: JuDocException
    m::String
end

#
# ASSET PATH error
#

"""A relative path was erroneous."""
struct RelativePathError <: JuDocException
    m::String
end

"""A file was not found."""
struct FileNotFoundError <: JuDocException
    m::String
end
