
# Where are parameters stored? In a `ParamVector` or in the object directly?
struct ParamsInVector end
struct ParamsInObject end


struct IdentityMap end;


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