export CalArray

function make_test_cal_array(name:: Symbol, N :: Integer; 
    allFixed = false, offset = 0.0)

    rng = MersenneTwister(23);
    sizeV = 2 : (1 + N);
    sz = (sizeV..., );

    T1 = Float64;
    defaultValue = randn(rng, T1, sz) .+ offset;
    lb = defaultValue .- one(T1);
    ub = defaultValue .+ one(T1);
    if allFixed
        isCalM = trues(size(lb));
    else
        isCalM = Matrix{Bool}(defaultValue .> 0.0);
    end

    ca = CalArray(name, string(name), string(name), defaultValue .+ 0.1, defaultValue, lb, ub, isCalM);
    return ca
end


## -------------  Basics

Base.size(ca :: CalArray{T1, N}) where {T1, N} = 
    size(ca.defaultValue);
Base.show(io :: IO,  p :: CalArray{T1, N}) where {T1, N} = 
    print(io, "CalArray:  " * show_string(p));

is_calibrated(ca :: CalArray{T1, N}) where {T1, N} = any(ca.isCalM);


# Returns a Vector with the calibrated parameter values (or empty).
calibrated_value(ca :: CalArray{T1, N}) where {T1, N} = 
    calibrated_elements(ca, ca.value);

calibrated_lb(ca :: CalArray{T1, N}) where {T1, N} = 
    calibrated_elements(ca, ca.lb);

calibrated_ub(ca :: CalArray{T1, N}) where {T1, N} =
    calibrated_elements(ca, ca.ub);


function calibrated_elements(ca :: CalArray{T1, N}, m :: AbstractArray{T1, N}) where {T1, N}
    if is_calibrated(ca)
        v = m[map_indices(ca)];
    else
        v = Array{T1,N}();
    end
    return v
end


## --------  Validate

function validate(ca :: CalArray{T1, N}; silent = true) where {T1, N}
    isValid = true;
    isValid = isValid  && (size(ca.defaultValue) == size(ca.lb) == size(ca.ub) == size(ca.isCalM));
    # isValid = isValid  &&  check_values(ca);
    return isValid
end

# function check_values(ca :: CalArray{T1, N}) where {T1, N}
#     isValid = check_calibrated_values(ca)  &&  check_fixed_values(ca);
#     return isValid
# end

# function check_calibrated_values(ca :: CalArray{T1, N}) where {T1, N}
#     idxV = map_indices(ca);
#     isempty(idxV)  &&  return true;

#     calValueV = ca.valueM[idxV];
#     isValid = isapprox(calValueV, ca.calValueV);

#     pvec = get_pvector(ca);
#     isValid = isValid  &&  isapprox(calValueV, param_value(pvec, :calValueV));
#     return isValid
# end


# function check_fixed_values(ca :: CalArray{T1, N}) where {T1, N}
#     valueM = values(ca);
#     isValid = true;
#     for (j, isCal) in enumerate(ca.isCalM)
#         if !isCal
#             isValid = isValid && (valueM[j] ≈ ca.defaultValue[j]);
#         end
#     end
#     return isValid
# end


## ------------  Retrieve

function value(ca :: CalArray{T1, N}) where {T1, N}
    # update_values!(ca);
    return ca.value;
end

# function update_values!(ca :: CalArray{T1, N}) where {T1, N}
#     ca.value .= ca.defaultValue;
#     idxV = map_indices(ca);
#     for (j, idx) in enumerate(idxV)
#         ca.value[idx] = ca.value[];
#     end
# end

# Linear index into arrays for each calibrated value.
function map_indices(ca :: CalArray{T1, N}) where {T1, N}
    nCal = sum(ca.isCalM);
    if nCal > 0
        idxV = zeros(Int, nCal);
        j2 = 0;
        for (j, isCal) in enumerate(ca.isCalM)
            if isCal
                j2 += 1;
                idxV[j2] = j;
            end
        end
        @assert j2 == nCal;
    else
        idxV = Vector{Int}();
    end
    return idxV
end


## ----------  Change / update

"""
    $(SIGNATURES)

Change calibration status to `true`
"""
function calibrate!(p :: CalArray{T1, N}) where {T1, N}
    p.isCalM .= true
    return nothing
end


"""
    $(SIGNATURES)

Change calibration status to `false`
"""
function fix!(p :: CalArray{T1, N}; pValue = nothing) where {T1, N}
    p.isCalM .= false;
    if !isnothing(pValue)
        # set_value!(p, pValue);
        set_default_value!(p, pValue);
    end
    return nothing
end


# Used in calibration. Input should match dimension of calibrated params.
function set_calibrated_value!(ca :: CalArray{T1, N}, vIn :: AbstractVector{T1};
    skipInvalidSize = false) where {T1, N}

    idxV = map_indices(ca);
    if size(idxV) == size(vIn)
        ca.value[idxV] .= vIn;
    else
        @warn """
            Invalid size of new calibrated values for $ca
            Given: $(size(vIn))
            Expected: $(size(idxV))
            """
        skipInvalidSize  ||  error("Stopped");
    end
end

# ---------------