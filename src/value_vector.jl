## ------------  ValueVector

values(vv :: ValueVector) = vv.valueV;
lb(vv :: ValueVector) = vv.lbV;
ub(vv :: ValueVector) = vv.ubV;
pnames(vv :: ValueVector) = vv.pNameV;
Base.length(vv :: ValueVector) = Base.length(vv.valueV);

function Base.isapprox(vv1 :: ValueVector, vv2 :: ValueVector;
    atol :: Real = 1e-8)

    return isapprox(values(vv1), values(vv2), atol = atol)  &&
        isapprox(lb(vv1), lb(vv2), atol = atol)  &&
        isapprox(ub(vv1), ub(vv2), atol = atol)  &&
        isequal(pnames(vv1), pnames(vv2));
end


"""
	$(SIGNATURES)

Set values.
"""
function set_values(vv :: ValueVector, valueV)
    @assert size(valueV) == size(lb(vv))  "Size mismatch"
    vv.valueV = deepcopy(valueV);
    return nothing
end

random_guess(vv :: ValueVector, rng :: AbstractRNG) =
    lb(vv) .+ (ub(vv) .- lb(vv)) .* rand(rng, length(vv));


# ----------------