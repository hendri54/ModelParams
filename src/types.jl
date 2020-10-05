# abstract type ModelObject end

# include("id_types.jl")
include("transformation_types.jl")
include("param_types.jl")
include("deviation_types.jl")


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


"""
	$(SIGNATURES)

Table that shows how each parameter affects each deviation.
Rows are deviations. Columns are parameters.
"""
mutable struct ChangeTable{T1 <: AbstractFloat}
    # Name of each parameter
    paramNameV
    # Name of each deviation
    devNameV
    # Vector of intial deviations
    dev0V :: Vector{T1}
    # Matrix of deviations by [deviation, parameter]
    devM :: Matrix{T1}
    # Scalar deviations for all parameters
    scalarDevV :: Vector{T1}
    scalarDev0 :: T1
end


# -----------