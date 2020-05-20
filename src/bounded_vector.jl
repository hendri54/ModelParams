## --------------  BoundedVector

"""
	$(SIGNATURES)

Initialize the `ParamVector`. Requires `dxV` to be set.
Note that bounds on `dxV` must be between 0 and 1.
"""
function set_pvector!(iv :: BoundedVector{T1};
    name :: Symbol = :dxV,  description = "Increments", 
    symbol = "dxV", isCalibrated :: Bool = true) where T1
    
    defaultValueV = iv.dxV;
    n = length(defaultValueV);
    p = Param(name, description, symbol, defaultValueV, defaultValueV, 
        zeros(T1, n), ones(T1, n), isCalibrated);
    iv.pvec = ParamVector(iv.objId, [p]);
    return nothing
end

is_increasing(iv :: BoundedVector{T1}) where T1 = iv.increasing;
lb(iv :: BoundedVector{T1}) where T1 = iv.lb;
ub(iv :: BoundedVector{T1}) where T1 = iv.ub;
Base.length(iv :: BoundedVector{T1}) where T1 =
    Base.length(iv.dxV);

function values(iv :: BoundedVector{T1}) where T1
    n = length(iv);
    valueV = zeros(T1, n);
    if is_increasing(iv)
        valueV[1] = lb(iv) + iv.dxV[1] * (ub(iv) - lb(iv));
        for j = 2 : n
            valueV[j] = valueV[j-1] + iv.dxV[j] * (ub(iv) - valueV[j-1]);
        end
    else
        valueV[1] = ub(iv) - iv.dxV[1] * (ub(iv) - lb(iv));
        for j = 2 : n
            valueV[j] = valueV[j-1] - iv.dxV[j] * (valueV[j-1] - lb(iv));
        end
    end
    return valueV
end

values(iv :: BoundedVector{T1}, idx) where T1 =
    values(iv)[idx];

# ----------------