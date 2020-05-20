"""
    ModelObject

Abstract model object
Must have field `objId :: ObjectId` that uniquely identifies it
May contain a ParamVector, but need not.

Child objects may be vectors. Then the vector must have a fixed element type that is
a subtype of `ModelObject`
"""
abstract type ModelObject end

include("id_types.jl")
include("transformation_types.jl")


"""
    Param

Holds information about one potentially calibrated parameter (array).
Default value must always be set. Determines size of inputs.
Everything else can be either empty or must have the same size.
"""
mutable struct Param{T1 <: Any}
    name :: Symbol
    description :: String
    symbol :: String
    value :: T1
    defaultValue :: T1
    "Value bounds"
    lb :: T1
    ub :: T1
    isCalibrated :: Bool
end


## ----------  ParamVector

"""
    ParamVector

Vector containing all of a model's potentially calibrated parameters.
Parameters contain values, not just default values
They are kept in sync with values in object

Intended workflow:
    See `SampleModel`
    Create a model object with parameters as fields
        Otherwise the code gets too cumbersome
        Constructor initializes ParamVector with defaults (or user inputs)
    During calibration
        Each object generates a Dict of calibrated parameters
        Make this into a vector of Floats that can be passed to the optimizer.
        Optimization algorithm changes the floats
        Make floats back into Dict
        Copy back into model objects

Going from a vector of Dicts to a vector of Floats and back:
    `make_guess`
    `set_params_from_guess!`
    These are called on the top level model object

# ToDo: Make the process of going from model -> vector and vice versa more robust.
    Currently, the user has to ensure that the ordering of ParamVectors and model
    objects never changes.
"""
@with_kw_noshow mutable struct ParamVector
    "ObjectId of the ModelObject. To ensure that no mismatches occur."
    objId :: ObjectId
    # A Dict would be natural, but it helps to preserve the order of the params
    pv :: Vector{Param} = Vector{Param{Any}}()
    "Governs scaling of parameters into guess vectors for optimization"
    pTransform :: ParamTransformation = LinearTransformation(lb = 1.0, ub = 2.0)
end


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



## ---------------  ChangeTable

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

include("param_types.jl")
include("deviation_types.jl")

# -----------