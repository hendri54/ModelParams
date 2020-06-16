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


"""
	$(SIGNATURES)

Increasing or decreasing vector with bounds.

A `BoundedVector` is typically constructed with an empty `ParamVector`. Then [`set_pvector!`](@ref) is used to initialize the `ParamVector`.
The `ParamVector` contains a single entry which must be named `:dxV`. It sets the values for the eponymous `BoundedVector` field.
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