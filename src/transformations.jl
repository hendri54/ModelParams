"""
	$(SIGNATURES)

Tranform parameter into bounds specified by `LinearTransformation`.
Out of bounds values are pushed inside bounds with a warning.
"""
function transform_param(tr :: LinearTransformation{F1}, p :: Param{F2}) where {F1, F2}
    # pValue = enforce_bounds(value(p), lb(p), ub(p));
    pValue = clamp.(value(p), lb(p), ub(p));
    # if any(value(p) .> p.ub)  ||  any(value(p) .< p.lb)
    #     @warn "Values out of bounds for $(p.name)."
    #     value = min.(p.ub, max.(p.lb, value(p)));
    # else
    #     value = value(p);
    # end
    return lb(tr) .+ (ub(tr) .- lb(tr)) .* (pValue .- lb(p)) ./ (ub(p) .- lb(p));
end

# function enforce_bounds(valueIn :: F1, lb :: F1, ub :: F1) where F1 <: Real
#     return F1(min(ub, max(lb, valueIn)));
# end

# Expecting bounds to be of the same dimensions as valueIn.
# function enforce_bounds(valueIn :: AbstractArray{F1}, 
#     lb :: AbstractArray{F1}, ub :: AbstractArray{F1}) where F1 <: Real

#     @assert size(lb) == size(ub) == size(valueIn);
#     pValue = copy(valueIn);
#     for (j, vIn) in enumerate(valueIn)
#         if vIn > ub[j]
#             pValue[j] = ub[j];
#         end
#         if vIn < lb[j]
#             pValue[j] = lb[j];
#         end
#     end
#     return value
# end


"""
	$(SIGNATURES)

Undo parameter transformation.

`value` must be the same size as `value(p)`.
"""
function untransform_param(tr :: LinearTransformation{F1}, 
    p :: Param, pValue) where F1

    @assert size(pValue) == size(value(p))  "Size mismatch: $(size(pValue)) vs $(size(value(p))) for $p"
    @assert all(pValue .<= ub(tr))  "Values to high: $pValue  vs  $(ub(tr))"
    @assert all(pValue .>= lb(tr))
    outV = lb(p) .+ (ub(p) .- lb(p)) .* (pValue .- lb(tr)) ./ (ub(tr) .- lb(tr));
    @assert size(outV) == size(pValue)
    return outV
end

# function untransform(tr :: LinearTransformation{F1}) where F1


"""
	$(SIGNATURES)

Bounds on transformed parameters.
"""
function transform_bounds(tr :: LinearTransformation{F1}) where F1
    return lb(tr), ub(tr)
end

# -------