## Linear Transformation


"""
	$(SIGNATURES)

Tranform parameter into bounds specified by `LinearTransformation`.
"""
function transform_param(tr :: LinearTransformation, p :: Param)
    @assert all(p.value .<= p.ub)
    @assert all(p.value .>= p.lb)
    return tr.lb .+ (tr.ub .- tr.lb) .* (p.value .- p.lb) ./ (p.ub .- p.lb);
end


"""
	$(SIGNATURES)

Undo parameter transformation.

`value` must be the same size as `p.value`.
"""
function untransform_param(tr :: LinearTransformation, p :: Param, value)
    @assert size(value) == size(p.value)  "Size mismatch: $(size(value)) vs $(size(p.value))"
    @assert all(value .<= tr.ub)
    @assert all(value .>= tr.lb)
    outV = p.lb .+ (p.ub .- p.lb) .* (value .- tr.lb) ./ (tr.ub .- tr.lb);
    @assert size(outV) == size(value)
    return outV
end


"""
	$(SIGNATURES)

Bounds on transformed parameters.
"""
function transform_bounds(tr :: LinearTransformation)
    return tr.lb, tr.ub
end

# -------