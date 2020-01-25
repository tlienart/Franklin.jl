abstract type FranklinException <: Exception end

#
# Parsing related
#

"""An OCBlock was not parsed properly (e.g. the closing token was not found)."""
struct OCBlockError <: FranklinException
    m::String
    c::String
end

function Base.showerror(io::IO, be::OCBlockError)
    println(io, be.m)
    print(io, be.c)
end

"""A `\\newcommand` was not parsed properly."""
struct LxDefError <: FranklinException
    m::String
end

"""A latex command was found but could not be processed properly."""
struct LxComError <: FranklinException
    m::String
end

"""A math block name failed to parse."""
struct MathBlockError <: FranklinException
    m::String
end

"""A Page Variable wasn't set properly."""
struct PageVariableError <: FranklinException
    m::String
end

#
# HTML related
#

"""An HTML block (e.g. [`HCond`](@see)) was erroneous."""
struct HTMLBlockError <: FranklinException
    m::String
end

"""An HTML function (e.g. `{{fill ...}}`) failed."""
struct HTMLFunctionError <: FranklinException
    m::String
end

#
# ASSET PATH error
#

"""A relative path was erroneous."""
struct RelativePathError <: FranklinException
    m::String
end

"""A file was not found."""
struct FileNotFoundError <: FranklinException
    m::String
end

#
# CODE
#

"""A relative path was erroneous for Literate."""
struct LiterateRelativePathError <: FranklinException
    m::String
end
