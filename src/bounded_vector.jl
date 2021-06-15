## --------------  BoundedVector

"""
	$(SIGNATURES)

Initialize the `ParamVector`. Requires `dxV` to be set.
Note that bounds on `dxV` must be between 0 and 1.
This is called after the `BoundedVector` has been constructed with an empty `ParamVector` but with the values of the field `dxV` set to reasonable defaults.

# Example
```
dxV = [0.3, 0.2, 0.8];
b = BoundedVector(objId, ParamVector(objId), true, 1.0, 2.0, dxV);
set_pvector!(b; description = "Gradient", symbol = "g(x)");
```
"""
function set_pvector!(iv :: BoundedVector{T1};
    description = "Increments", 
    symbol = "dxV", 
    isCalibrated :: Bool = true) where T1
    
    defaultValueV = iv.dxV;
    n = length(defaultValueV);
    p = Param(:dxV, description, symbol, defaultValueV, defaultValueV, 
        zeros(T1, n), ones(T1, n), isCalibrated);
    iv.pvec = ParamVector(iv.objId, [p]);
    return nothing
end

is_increasing(iv :: BoundedVector{T1}) where T1 = iv.increasing;
lb(iv :: BoundedVector{T1}) where T1 = iv.lb;
ub(iv :: BoundedVector{T1}) where T1 = iv.ub;
Base.length(iv :: BoundedVector{T1}) where T1 =
    Base.length(iv.dxV);

function calibrate_values!(iv :: BoundedVector{T1}) where T1
    p = iv.pvec[1];
    @assert name(p) == :dxV
    calibrate!(p);
end


"""
	$(SIGNATURES)

Switches calibration toggle off. Sets values and default values everywhere. The end result is a `BoundedVector` with fixed (not calibrated) increments that result in values of `valueV`.
"""
function fix_values!(iv :: BoundedVector{T1}, 
    valueV :: AbstractVector{T1}) where T1

    dxV = values_to_dx(iv, valueV);
    p = iv.pvec[1];
    @assert name(p) == :dxV
    set_value!(p, valueV);
    set_default_value!(p, valueV);
    fix!(p);
    iv.dxV = dxV;
end


"""
	$(SIGNATURES)

Returns all values of a `BoundedVector`.
"""
function values(iv :: BoundedVector{T1}) where T1
    valueV = dx_to_values(iv, iv.dxV);
    return valueV
end

function dx_to_values(iv :: BoundedVector{T1}, dxV) where T1
    n = length(iv);
    valueV = zeros(T1, n);
    if is_increasing(iv)
        valueV[1] = lb(iv) + dxV[1] * (ub(iv) - lb(iv));
        if n > 1
            for j = 2 : n
                valueV[j] = valueV[j-1] + dxV[j] * (ub(iv) - valueV[j-1]);
            end
        end
    else
        valueV[1] = ub(iv) - dxV[1] * (ub(iv) - lb(iv));
        if n > 1
            for j = 2 : n
                valueV[j] = valueV[j-1] - dxV[j] * (valueV[j-1] - lb(iv));
            end
        end
    end
    return valueV
end


"""
	$(SIGNATURES)

Returns a subset of the values of a `BoundedVector`.
"""
values(iv :: BoundedVector{T1}, idx) where T1 =
    values(iv)[idx];


"""
	$(SIGNATURES)

Set the default values of a `BoundedVector`.
"""
function set_default_value!(iv :: BoundedVector{T1}, 
    valueV :: AbstractVector{T1}) where T1

    dxV = values_to_dx(iv, valueV);
    p = iv.pvec[1];
    @assert name(p) == :dxV
    set_default_value!(p, valueV)
end


function values_to_dx(iv :: BoundedVector{T1}, valueV :: AbstractVector{T1}) where T1
    @assert check_values(iv, valueV);
    n = length(iv);
    dxV = zeros(T1, n);

    if is_increasing(iv)
        dxV[1] = (valueV[1] - lb(iv)) / (ub(iv) - lb(iv));
        if n > 1
            for j = 2 : n
                dxV[j] = (valueV[j] - valueV[j-1]) / (ub(iv) - valueV[j-1]);
            end
        end
    else
        dxV[1] = (ub(iv) - valueV[1]) / (ub(iv) - lb(iv));
        if n > 1
            for j = 2 : n
                dxV[j] = (valueV[j-1] - valueV[j]) / (valueV[j-1] - lb(iv));
            end
        end
    end
    return dxV
end


function check_values(iv :: BoundedVector{T1}, valueV :: AbstractVector{T1}) where T1
    isValid = true;
    isValid = isValid  &&  isequal(length(valueV), length(iv));
    isValid = isValid  &&  all(valueV .>= lb(iv));
    isValid = isValid  &&  all(valueV .<= ub(iv));
    if is_increasing(iv)
        isValid = isValid  &&  all(diff(valueV) .> 0.0);
    else
        isValid = isValid  &&  all(diff(valueV) .< 0.0);
    end
    return isValid
end


function param_table(iv :: BoundedVector{T1}, isCalibrated :: Bool) where T1
    p = iv.pvec[1];
    if isCalibrated == p.isCalibrated
        pt = ParamTable(1);
        set_row!(pt, 1, string(p.name), p.symbol, p.description, 
            formatted_value(values(iv)));
    else
        pt = nothing;
    end
    return pt
end

# ----------------