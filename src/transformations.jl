"""
	$(SIGNATURES)

Tranform parameter into bounds specified by `LinearTransformation`. Calibrated values only.
Out of bounds values are pushed inside bounds with a warning.
"""
function transform_param(tr :: LinearTransformation{F1}, p :: AbstractParam) where F1
    pValue = clamp.(calibrated_value(p), calibrated_lb(p), calibrated_ub(p));
    # if any(value(p) .> p.ub)  ||  any(value(p) .< p.lb)
    #     @warn "Values out of bounds for $(p.name)."
    #     value = min.(p.ub, max.(p.lb, value(p)));
    # else
    #     value = value(p);
    # end
    return param_lb(tr) .+ (param_ub(tr) .- param_lb(tr)) .* (pValue .- calibrated_lb(p)) ./ (calibrated_ub(p) .- calibrated_lb(p));
end


"""
	$(SIGNATURES)

Undo parameter transformation. Calibrated values only.

`value` must be the same size as `pvalue(p)`.
"""
function untransform_param(tr :: LinearTransformation{F1}, 
    p :: AbstractParam, pValue) where F1

    @assert size(pValue) == size(calibrated_value(p))  "Size mismatch: $(size(pValue)) vs $(size(calibrated_value(p))) for $p";

    if any(pValue .> param_ub(tr))  ||  any(pValue .< param_lb(tr))
        @warn """
            Values for $p out of bounds:
            $pValue
            """;
    end
    # @assert all(pValue .<= param_ub(tr))  "Values to high: $pValue  vs  $(param_ub(tr))"
    # @assert all(pValue .>= param_lb(tr))

    outV = clamp.(
        calibrated_lb(p) .+ 
        (calibrated_ub(p) .- calibrated_lb(p)) .* (pValue .- param_lb(tr)) ./ 
            (param_ub(tr) .- param_lb(tr)),
        calibrated_lb(p), calibrated_ub(p));
    
    @assert size(outV) == size(pValue);
    return outV
end

# function untransform(tr :: LinearTransformation{F1}) where F1


"""
	$(SIGNATURES)

Bounds on transformed parameters.
"""
function transform_bounds(tr :: LinearTransformation{F1}) where F1
    return param_lb(tr), param_ub(tr)
end

# -------