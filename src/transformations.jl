"""
	$(SIGNATURES)

Tranform parameter into bounds specified by `LinearTransformation`.
Out of bounds values are pushed inside bounds with a warning.
"""
function transform_param(tr :: LinearTransformation{F1}, p :: Param) where F1
    value = enforce_bounds(p.value, lb(p), ub(p));
    # if any(p.value .> p.ub)  ||  any(p.value .< p.lb)
    #     @warn "Values out of bounds for $(p.name)."
    #     value = min.(p.ub, max.(p.lb, p.value));
    # else
    #     value = p.value;
    # end
    return lb(tr) .+ (ub(tr) .- lb(tr)) .* (value .- p.lb) ./ (p.ub .- p.lb);
end

function enforce_bounds(valueIn :: F1, lb :: F1, ub :: F1) where F1 <: Real
    return F1(min(ub, max(lb, valueIn)));
end

# Expecting bounds to be of the same dimensions as valueIn.
function enforce_bounds(valueIn :: AbstractArray{F1}, 
    lb :: AbstractArray{F1}, ub :: AbstractArray{F1}) where F1 <: Real

    @assert size(lb) == size(ub) == size(valueIn);
    value = copy(valueIn);
    for (j, vIn) in enumerate(valueIn)
        if vIn > ub[j]
            value[j] = ub[j];
        end
        if vIn < lb[j]
            value[j] = lb[j];
        end
    end
    return value
end


"""
	$(SIGNATURES)

Undo parameter transformation.

`value` must be the same size as `p.value`.
"""
function untransform_param(tr :: LinearTransformation{F1}, p :: Param, value) where F1
    @assert size(value) == size(p.value)  "Size mismatch: $(size(value)) vs $(size(p.value)) for $p"
    @assert all(value .<= ub(tr))  "Values to high: $value  vs  $(ub(tr))"
    @assert all(value .>= lb(tr))
    outV = p.lb .+ (p.ub .- p.lb) .* (value .- lb(tr)) ./ (ub(tr) .- lb(tr));
    @assert size(outV) == size(value)
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