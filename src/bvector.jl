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

calibrated_value(ca :: BVector{T1}) where T1 = 
    is_calibrated(ca)  ?  ca.dxV  :  nothing;
calibrated_lb(ca :: BVector{T1}) where T1 = zeros(T1, length(ca));
calibrated_ub(ca :: BVector{T1}) where T1 = ones(T1, length(ca));

function validate(ca :: BVector{T1}; silent :: Bool = false) where T1
    isValid = all(x -> x >= zero(T1), ca.dxV)  &&  all(x -> x <= one(T1), ca.dxV);
    return isValid
end


is_increasing(iv :: BVector{T1}) where T1 = (iv.increasing == :increasing);
is_decreasing(iv :: BVector{T1}) where T1 = (iv.increasing == :decreasing);
is_nonmonotone(iv :: BVector{T1}) where T1 = (iv.increasing == :nonmonotone);
# For consistency, this returns a Vector
lb(iv :: BVector{T1}) where T1 = fill(iv.lb, size(iv));
ub(iv :: BVector{T1}) where T1 = fill(iv.ub, size(iv));
# Scalar bounds across all elements
scalar_lb(iv :: BVector{T1}) where T1 = iv.lb;
scalar_ub(iv :: BVector{T1}) where T1 = iv.ub;


## -----------  Retrieve

"""
	$(SIGNATURES)

Returns all values of a `BoundedVector`.
"""
value(iv :: BVector{T1}) where T1 = 
    dx_to_values(iv, iv.dxV);

default_value(iv :: BVector{T1}) where T1 = 
    dx_to_values(iv, iv.defaultDxV);

# Input is in terms of untransformed units.
function fix!(iv :: BVector{T1}; pValue = nothing) where T1
   iv.isCalibrated = false;
   isnothing(pValue)  ||  set_default_value!(iv, pValue); 
end

# The input is in untransformed units.
function set_value!(iv :: BVector{T1}, vIn;
    skipInvalidSize = false) where T1

    oldValue = value(iv);
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

# Input is in terms of dxV
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
function set_default_value!(iv :: BVector{T1}, vIn :: AbstractVector{T1}) where T1
    iv.defaultDxV = values_to_dx(iv, vIn);
end

# Bounds have to be scalar or vector with all equal elements.
function set_bounds!(iv :: BVector{T1}; lb = nothing, ub = nothing)  where T1
    isnothing(lb)  ||  set_lower_bound!(iv, lb);
    isnothing(ub)  ||  set_upper_bound!(iv, ub);
    @assert size(ModelParams.lb(iv)) == size(ModelParams.ub(iv)) == size(iv);
end

set_lower_bound!(iv :: BVector{T1}, lb) where T1 = iv.lb = vec_to_scalar(lb);
set_upper_bound!(iv :: BVector{T1}, ub) where T1 = iv.ub = vec_to_scalar(ub);

vec_to_scalar(v :: F1) where F1 <: Real = v;

function vec_to_scalar(v :: AbstractVector{F1}) where F1 <: Real
    @assert all(isapprox.(v, first(v)))  "All elements expected to be the same.";
    return first(v)
end

# -------------