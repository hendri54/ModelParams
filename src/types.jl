include("transformation_types.jl");
include("param_types.jl")


"""
	$(SIGNATURES)

Object that holds vectorized version of calibrated parameter values.
This can be passed into numerical optimizers.
Also stores the name of the `Param` for each entry. This ensures that going back from vector to `Dict` is correct.
"""
mutable struct ValueVector{T <: AbstractFloat}
    valueV :: Vector{T}
    lbV :: Vector{T}
    ubV :: Vector{T}
    pNameV :: Vector{Symbol}
end


# -----------