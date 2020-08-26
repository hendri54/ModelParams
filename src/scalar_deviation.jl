function empty_scalar_deviation(F1 = Float64)
    return ScalarDeviation{F1}(name = :empty)
end

get_weights(d :: ScalarDeviation{F1}) where F1 = one(F1);


function scalar_dev(d :: ScalarDeviation; inclScalarWt :: Bool = true)
    # scalarDev = abs(d.modelV - d.dataV) * d.wtV;
    scalarDev = scalar_deviation(d.modelV, d.dataV, d.wtV; p = norm_p(d));
    if inclScalarWt
        scalarDev *= d.scalarWt;
    end
    scalarStr = sprintf1(d.fmtStr, scalarDev);
    return scalarDev, scalarStr
end

data_se(d :: ScalarDeviation{F1}) where F1 = d.stdV;


## -------------  Show

Base.show(io :: IO, d :: ScalarDeviation{F1}) where F1 = 
    Base.print(io, "$(name(d)):  ", short_description(d));


"""
    $(SIGNATURES)

Show a scalar deviation. Fallback if not user-defined function is provided.
Appends to the provided file (if any).
"""
function scalar_show_fct(d :: ScalarDeviation; showModel :: Bool = true, fPath :: String = "")
    io = open_show_path(d, fPath = fPath, writeMode = "a");
    write(io, scalar_show_string(d) * "\n");
    close_show_path(d, io);
    return nothing
end

function scalar_show_string(d :: ScalarDeviation{F1}; showModel :: Bool = true) where F1
    if showModel
        mStr = " model: " * sprintf1(d.fmtStr, d.modelV);
    else
        mStr = "";
    end
    dStr = sprintf1(d.fmtStr, d.dataV);
    if data_se(d) > zero(F1)
        seStr = "(" * sprintf1(d.fmtStr, d.stdV) * ")";
    else
        seStr = "";
    end
    return "$(d.name): $mStr  data: $dStr $seStr"
end




# ---------------