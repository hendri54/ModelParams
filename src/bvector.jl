export BVector

function make_test_bvector(name:: Symbol; 
    isCalibrated :: Bool = true,
    increasing :: Symbol = :increasing, offset = 0.0)

    n = 4;
    defaultValue = collect(LinRange(0.3, 0.2, n));
    ca = BVector(name, string(name), string(name), defaultValue .+ 0.1, defaultValue, 
    -2.0 + offset, 3.0 + offset, isCalibrated,
    increasing);
    return ca
end


## -------------  Basics

# Need those because they are otherwise defined in terms of `default_value`
Base.size(ca :: BVector{T1}) where T1 = size(ca.defaultDxV);
Base.length(ca :: BVector{T1}) where T1 = length(ca.defaultDxV);
Base.show(io :: IO,  p :: BVector{T1}) where T1 = 
    print(io, "BVector:  " * show_string(p));

# is_calibrated(ca :: BVector{T1}) where T1 = ca.isCalibrated;

function calibrated_value(ca :: BVector; returnIfFixed = true) 
    if is_calibrated(ca)  ||  returnIfFixed
        return ca.dxV  
    else
        return missing;
    end
end

calibrated_lb(ca :: BVector{T1}) where T1 = fill(ca.lb, size(ca));
    # zeros(T1, length(ca));
calibrated_ub(ca :: BVector{T1}) where T1 = fill(ca.ub, size(ca));
    # ones(T1, length(ca));

function validate(ca :: BVector{T1}; silent :: Bool = false) where T1
    isValid = all(x -> x >= zero(T1), ca.dxV)  &&  all(x -> x <= one(T1), ca.dxV);
    return isValid
end


is_increasing(iv :: BVector{T1}) where T1 = (iv.increasing == :increasing);
is_decreasing(iv :: BVector{T1}) where T1 = (iv.increasing == :decreasing);
is_nonmonotone(iv :: BVector{T1}) where T1 = (iv.increasing == :nonmonotone);
# For consistency, this returns a Vector
param_lb(iv :: BVector{T1}) where T1 = calibrated_lb(iv); # fill(iv.lb, size(iv));
param_ub(iv :: BVector{T1}) where T1 = calibrated_ub(iv); # fill(iv.ub, size(iv));
# Scalar bounds (user facing)
scalar_lb(iv :: BVector{T1}) where T1 = iv.lb;
scalar_ub(iv :: BVector{T1}) where T1 = iv.ub;


## -----------  Retrieve

# """
# 	$(SIGNATURES)

# Returns all values of a `BVector`.
# """
# function pvalue(iv :: BVector{T1}) where T1 
#     if is_calibrated(iv)
#         dx_to_values(iv, iv.dxV);
#     else
#         return default_value(iv);
#     end
# end

calibrated_value_user_facing(iv :: BVector) = dx_to_values(iv, iv.dxV);
default_value_user_facing(iv :: BVector) = dx_to_values(iv, iv.defaultDxV);

# Not user facing
calibrated_value_only(iv :: BVector) = iv.dxV;
default_value(iv :: BVector{T1}) where T1 = iv.defaultDxV;
    # dx_to_values(iv, iv.defaultDxV);

# Input is in terms of untransformed units. Not user facing.
function fix!(iv :: BVector{T1}; pValue = nothing) where T1
   iv.isCalibrated = false;
   isnothing(pValue)  ||  set_default_value!(iv, pValue); 
end

# The input is in untransformed (user facing) units.
function set_calibrated_value_user_facing!(iv :: BVector{T1}, vIn;
    skipInvalidSize = false) where T1

    oldValue = pvalue(iv);
    if size(iv) == size(vIn)  
        iv.dxV = values_to_dx(iv, vIn);
    else
        @warn("""
            Wrong size for $iv
            Given: $(size(vIn))
            Expected: $(size(iv))
            """);
        if !skipInvalidSize
            error("Stopped");
        end
    end
    return oldValue
end

# Input is in terms of dxV. Not user facing.
function set_calibrated_value!(iv :: BVector{T1}, vIn :: AbstractVector{T1};
    skipInvalidSize = false) where T1
    
    if size(iv) == size(vIn)
        iv.dxV .= vIn;
    else
        @warn """
            Invalid size of new calibrated values for $iv
            Given: $(size(vIn))
            Expected: $(size(iv))
            """
        skipInvalidSize  ||  error("Stopped");
    end
end

# Input is in untransformed units.
function set_default_value_user_facing!(iv :: BVector{T1}, 
        vIn :: AbstractVector{T1}) where T1
    iv.defaultDxV = values_to_dx(iv, vIn);
end

function set_default_value!(iv :: BVector{T1}, vIn :: AbstractVector{T1}) where T1
    iv.defaultDxV .= vIn;
end

# Bounds have to be scalar or vector with all equal elements.
function set_bounds!(iv :: BVector{T1}; lb = nothing, ub = nothing)  where T1
    isnothing(lb)  ||  set_lower_bound!(iv, lb);
    isnothing(ub)  ||  set_upper_bound!(iv, ub);
    @assert size(param_lb(iv)) == size(param_ub(iv)) == size(iv);
end

set_lower_bound!(iv :: BVector{T1}, lb) where T1 = iv.lb = vec_to_scalar(lb);
set_upper_bound!(iv :: BVector{T1}, ub) where T1 = iv.ub = vec_to_scalar(ub);

vec_to_scalar(v :: F1) where F1 <: Real = v;

function vec_to_scalar(v :: AbstractVector{F1}) where F1 <: Real
    @assert all(isapprox.(v, first(v)))  "All elements expected to be the same.";
    return first(v)
end


function dx_to_values(iv :: BVector{T1}, dxV) where T1
    # n = length(iv);
    if is_increasing(iv)
        valueV = dx_to_values_increasing(dxV, scalar_lb(iv), scalar_ub(iv))
    elseif is_decreasing(iv)
        valueV = dx_to_values_decreasing(dxV, scalar_lb(iv), scalar_ub(iv))
    elseif is_nonmonotone(iv)
        valueV = copy(dxV);
    else
        error("Invalid");
    end
    return valueV
end

function dx_to_values_increasing(dxV, lb, ub)
    @check all(0.0 .<= dxV .<= 1.0);
    T1 = eltype(dxV);
    n = length(dxV);
    valueV = zeros(T1, n);
    valueV[1] = lb + dxV[1] * (ub - lb);
    if n > 1
        for j = 2 : n
            valueV[j] = valueV[j-1] + dxV[j] * (ub - valueV[j-1]);
        end
    end
    return valueV
end

function dx_to_values_decreasing(dxV, lb, ub)
    @check all(0.0 .<= dxV .<= 1.0);
    T1 = eltype(dxV);
    n = length(dxV);
    valueV = zeros(T1, n);
    valueV[1] = ub - dxV[1] * (ub - lb);
    if n > 1
        for j = 2 : n
            valueV[j] = valueV[j-1] - dxV[j] * (valueV[j-1] - lb);
        end
    end
    return valueV
end

function values_to_dx(iv :: BVector{T1}, valueV :: AbstractVector{T1}) where T1
    @assert check_values(iv, valueV);
    n = length(iv);

    if is_increasing(iv)
        dxV = values_to_dx_increasing(valueV, scalar_lb(iv), scalar_ub(iv));
    elseif is_decreasing(iv)
        dxV = values_to_dx_decreasing(valueV, scalar_lb(iv), scalar_ub(iv));
    elseif is_nonmonotone(iv)
        dxV = copy(valueV);
    else
        error("Invalid");
    end
    return dxV
end

function values_to_dx_increasing(valueV :: AbstractVector{T1}, lb, ub) where T1
    n = length(valueV);
    dxV = zeros(T1, n);
    dxV[1] = (valueV[1] - lb) / (ub - lb);
    if n > 1
        for j = 2 : n
            dxV[j] = (valueV[j] - valueV[j-1]) / (ub - valueV[j-1]);
        end
    end
    return dxV
end

function values_to_dx_decreasing(valueV :: AbstractVector{T1}, lb, ub) where T1
    n = length(valueV);
    dxV = zeros(T1, n);
    dxV[1] = (ub - valueV[1]) / (ub - lb);
    if n > 1
        for j = 2 : n
            dxV[j] = (valueV[j-1] - valueV[j]) / (valueV[j-1] - lb);
        end
    end
    return dxV
end


function check_values(iv :: BVector{T1}, valueV :: AbstractVector{T1}) where T1
    isValid = true;
    isValid = isValid  &&  isequal(length(valueV), length(iv));
    if any(valueV .< scalar_lb(iv))
        isValid = false;
        @warn "Values too low: $valueV";
    end
    if any(valueV .> scalar_ub(iv))
        isValid = false;
        @warn "Values too high: $valueV";
    end
    isValid = isValid  &&  all(valueV .<= scalar_ub(iv));
    if is_increasing(iv)
        isValid = isValid  &&  all(diff(valueV) .> 0.0);
    elseif is_decreasing(iv)
        isValid = isValid  &&  all(diff(valueV) .< 0.0);
    end
    return isValid
end


# -------------