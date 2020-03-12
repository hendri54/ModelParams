## Linear Transformation


"""
	$(SIGNATURES)

Tranform parameter into bounds specified by `LinearTransformation`.
Out of bounds values are pushed inside bounds with a warning.
"""
function transform_param(tr :: LinearTransformation, p :: Param)
    if any(p.value .> p.ub)  ||  any(p.value .< p.lb)
        @warn "Values out of bounds for $(p.name)."
        value = min.(p.ub, max.(p.lb, p.value));
    else
        value = p.value;
    end
    return tr.lb .+ (tr.ub .- tr.lb) .* (value .- p.lb) ./ (p.ub .- p.lb);
end


"""
	$(SIGNATURES)

Undo parameter transformation.

`value` must be the same size as `p.value`.
"""
function untransform_param(tr :: LinearTransformation, p :: Param, value)
    @assert size(value) == size(p.value)  "Size mismatch: $(size(value)) vs $(size(p.value)) for $p"
    @assert all(value .<= tr.ub)  "Values to high: $value  vs  $(tr.ub)"
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