## ----------  ObjectId

"""
    SingleId

Id for one object or object vector. 
Does not keep track of location in model.

`index` is used when there is a vector or matrix of objects of the same type
`index` is typically empty (scalar object) or scalar (vector objects)
"""
struct SingleId
    name :: Symbol
    index :: Array{Int}
end

function show_string(s :: SingleId)
    outStr = string(s.name);
    if !isempty(s.index)
        outStr = outStr * "$(s.index)";
    end
    return outStr
end

function show(io :: IO,  s :: SingleId)
    println(io,  "SingleId:  $(show_string(s))");
    return nothing
end


"""
    ObjectId

Complete, unique ID of a `ModelObject`

Contains own id and a vector of parent ids, so one knows exactly where the object
is placed in the model tree.
"""
struct ObjectId
    # Store IDs as vector, not tuple (b/c empty tuples are tricky)
    # "Youngest" member is positioned last in vector
    ids :: Vector{SingleId}
end


"""
    ParentId

This is actually identical to `ObjectId` but avoid recursive definitions
"""
struct ParentId
    ids :: Vector{SingleId}
end


## ----------  Parameters

"""
    Param

Holds information about one potentially calibrated parameter (array).
Default value must always be set. Determines size of inputs.
Everything else can be either empty or must have the same size.
"""
mutable struct Param{T1 <: Any, T2 <: AbstractString}
    name :: Symbol
    description :: T2
    symbol :: T2
    value :: T1
    defaultValue :: T1
    "Value bounds"
    lb :: T1
    ub :: T1
    isCalibrated :: Bool
end

function show_string(p :: Param)
    if p.isCalibrated
        calStr = "calibrated";
    else
        calStr = "fixed";
    end
    return string(p.name) * ": " * value_string(p) * "  ($calStr)"
end

function value_string(p :: Param)
    pType = eltype(p.value);
    if isa(p.value, Real)
        outStr = string(round(p.value, digits = 3));
    elseif isa(p.value, Array)
        outStr = "Array{$pType} of size $(size(p.value))";
    else
        outStr = "of type $pType";
    end
    return outStr
end

function show(io :: IO,  p :: Param)
    println(io, "Param:  " * show_string(p));
    return nothing
end



## ----------  Parameter Transformations

"""
	ParamTransformation

Abstract type for transforming parameters into bounded values (guesses) and reverse.

Define a concrete type with its own parameters and method
```julia
    transform_param(tr :: ParamTransformation, p :: Param)
```
"""
abstract type ParamTransformation end


"""
	LinearTransformation

Default linear transformation into default interval [1, 2].

Keyword constructor is provided.
"""
@with_kw struct LinearTransformation{T <: Real} <: ParamTransformation
    lb :: T = 1.0
    ub :: T = 2.0
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
    pv :: Vector{Param} = Vector{Param}()
    "Governs scaling of parameters into guess vectors for optimization"
    pTransform :: ParamTransformation = LinearTransformation(lb = 1.0, ub = 2.0)
end


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

function values(iv :: IncreasingVector)
	return iv.x0 .+ cumsum(vcat(zero(iv.x0), iv.dxV))
end

function length(iv :: IncreasingVector)
	return Base.length(iv.dxV) + 1
end


# -----------