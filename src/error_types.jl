#
# Parsing related
#
"""An OCBlock was not parsed properly (e.g. the closing token was not found)."""
struct OCBlockError <: Exception
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
