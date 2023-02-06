
# Where are parameters stored? In a `ParamVector` or in the object directly?
struct ParamsInVector end
struct ParamsInObject end


## Mappings from calibrated parameters to parameter values

abstract type AbstractMap end
# Each calibrated value is a parameter value: pvalue(p, j) = p.value[j]
struct IdentityMap <: AbstractMap end;
# One calibrated parameter for all indices: pvalue(p, j) = p.value
struct ScalarMap <: AbstractMap end;
# Each index belongs to exactly one group
struct GroupedMap{F1} <: AbstractMap 
    # Group that each index belongs to
    groupV :: Vector{Int}
    # Groups that are fixed and their fixed values
    fixedValueV :: Vector{Union{F1, Missing}}
end;


"""
	$(SIGNATURES)

Usually stores transformed values and bounds of the transformation.
`startIdx` refers to the start index in the `Vector{Float}` for all `ModelObject`s.
"""
mutable struct ParamInfo{T}
    pName :: Symbol
    startIdx :: Int
    # valueV :: T
    lbV :: T
    ubV :: T
end

mutable struct ValueVector{F1}
    d :: OrderedDict{Symbol, ParamInfo}
end

"""
	$(SIGNATURES)

Object that holds vectorized version of calibrated parameter values.
This can be passed into numerical optimizers.
Also stores the name of the `Param` for each entry. This ensures that going back from vector to `Dict` is correct.
"""
mutable struct Guess{T <: Real}
    d :: OrderedDict{ObjectId, ValueVector{T}}
end




# -----------