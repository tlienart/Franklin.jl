"""An HTML block (e.g. [`HCond`](@see)) was erroneous."""
struct HTMLBlockError <: Exception
    m::String
end

"""An HTML function (e.g. `{{fill ...}}`) failed."""
struct HTMLFunctionError <: Exception
    m::String
end
