
param_loc(::IncreasingVector{T1}) where T1 = ParamsInObject();
get_pvector(iv :: IncreasingVector{T1}) where T1 = 
    ParamVector(iv.objId, [iv.x0, iv.dxV]);

"""
	$(SIGNATURES)

Retrieve values of an `IncreasingVector`.
"""
values(iv :: IncreasingVector{T1}) where T1 =
	pvalue(iv.x0) .+ cumsum(vcat(zero(T1), pvalue(iv.dxV)));

values(iv :: IncreasingVector{T1}, idx) where T1 =
    values(iv)[idx];

Base.length(iv :: IncreasingVector) = Base.length(iv.dxV) + 1;


# Displays parameters in levels, not as intercept and increments.
function param_table(iv :: IncreasingVector{T1}, 
        isCalibrated :: Bool) where T1
    if isCalibrated
        # This is where we get the description and symbol from
        p = iv.dxV;
        pt = ParamTable(1);
        set_row!(pt, 1, string(p.name), p.symbol, p.description, 
            formatted_value(values(iv)));
    else
        pt = nothing;
    end
    return pt
end

# -----------------