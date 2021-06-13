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


## ----------  Parameters

"""
	IncreasingVector

Encodes an increasing vector of fixed length. Its values are calibrated.
"""
mutable struct IncreasingVector{T1} <: ModelObject
	objId :: ObjectId
	pvec :: ParamVector
	x0 :: T1
	dxV :: Vector{T1}
end

"""
	$(SIGNATURES)

Retrieve values of an `IncreasingVector`.
"""
values(iv :: IncreasingVector{T1}) where T1 =
	iv.x0 .+ cumsum(vcat(zero(T1), iv.dxV));

values(iv :: IncreasingVector{T1}, idx) where T1 =
    values(iv)[idx];

Base.length(iv :: IncreasingVector) = Base.length(iv.dxV) + 1;


# Displays parameters in levels, not as intercept and increments.
function param_table(iv :: IncreasingVector{T1}, isCalibrated :: Bool) where T1
    if isCalibrated
        # This is where we get the description and symbol from
        p = iv.pvec[2];
        pt = ParamTable(1);
        set_row!(pt, 1, string(p.name), p.symbol, p.description, 
            formatted_value(values(iv)));
    else
        pt = nothing;
    end
    return pt
end


"""
	$(SIGNATURES)

Increasing or decreasing vector with bounds.
The special case where the vector is of length 1 is supported.

A `BoundedVector` is typically constructed with an empty `ParamVector`. Then [`set_pvector!`](@ref) is used to initialize the `ParamVector`.
The `ParamVector` contains a single entry which must be named `:dxV`. It sets the values for the eponymous `BoundedVector` field. The `dxV` are typically in [0, 1]. They represent the increments in the vector.
"""
mutable struct BoundedVector{T1} <: ModelObject
    objId :: ObjectId
    pvec :: ParamVector
    increasing :: Bool
    # Values are in these bounds
    lb :: T1
    ub :: T1
    # Increments, typically in [0, 1]
    dxV :: Vector{T1}
end



# -----------