abstract type AbstractParam end

"""
    Param

Holds information about one potentially calibrated parameter (array).
Default value must always be set. Determines size of inputs.
Everything else can be either empty or must have the same size.
"""
mutable struct Param{T1 <: Any} <: AbstractParam
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
Base.@kwdef mutable struct ParamVector
    "ObjectId of the ModelObject. To ensure that no mismatches occur."
    objId :: ObjectId
    # A Dict would be natural, but it helps to preserve the order of the params
    # pv :: Vector{Param} = Vector{Param{Any}}()
    pv :: OrderedDict{Symbol, AbstractParam} = OrderedDict{Symbol, AbstractParam}()
    "Governs scaling of parameters into guess vectors for optimization"
    pTransform :: ParamTransformation = LinearTransformation{ValueType}()
end


"""
	$(SIGNATURES)

Collection of `ParamVector` for several `ModelObject`s.

Supports iteration like a `Dict`:

```julia
for (objId, pvec) in pvCollection
    @assert objId isa ObjectId
    @assert pvec isa ParamVector
end
```
"""
mutable struct PVectorCollection
    d :: OrderedDict{ObjectId, ParamVector}
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

# Example: 
```julia
bv = BoundedVector(objId, pvec, true, 5.0, 10.0, [0.5, 0.4]);
values(bv, 1) == 7.5;
values(bv, 2) == 7.5 + 0.4 * (10.0 - 7.5);
```
"""
mutable struct BoundedVector{T1} <: ModelObject
    objId :: ObjectId
    pvec :: ParamVector
    increasing :: Symbol
    # Values are in these bounds
    lb :: T1
    ub :: T1
    # Increments, typically in [0, 1]
    dxV :: Vector{T1}
end


"""
	$(SIGNATURES)

Array with some fixed and some calibrated parameters.
"""
mutable struct CalibratedArraySwitches{T1, N} <: ModelSwitches
    pvec :: ParamVector
    defaultValueM :: Array{T1, N}
    lbM :: Array{T1, N}
    ubM :: Array{T1, N}
    isCalM :: Array{Bool, N}
end

mutable struct CalibratedArray{T1, N} <: ModelObject
    objId :: ObjectId
    switches :: CalibratedArraySwitches{T1, N}
    calValueV :: Vector{T1}
    # This gets allocated once and then updated with calibrated 
    # values from calValueV
    valueM :: Array{T1, N}
end


mutable struct CalArray{T1, N} <: AbstractParam
    name :: Symbol
    description :: String
    symbol :: String
    value :: Array{T1, N}
    defaultValue :: Array{T1, N}
    lb :: Array{T1, N}
    ub :: Array{T1, N}
    isCalM :: Array{Bool, N}
end


# -----------