function empty_scalar_deviation()
    return ScalarDeviation(name = :empty)
end


function get_weights(d :: ScalarDeviation)
    return 1.0
end


function scalar_dev(d :: ScalarDeviation; inclScalarWt :: Bool = true)
    scalarDev = abs(d.modelV - d.dataV) * d.wtV;
    if inclScalarWt
        scalarDev *= d.scalarWt;
    end
    scalarStr = sprintf1(d.fmtStr, scalarDev);
    return scalarDev, scalarStr
end


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

function scalar_show_string(d :: ScalarDeviation; showModel :: Bool = true)
    if showModel
        mStr = " m: " * sprintf1(d.fmtStr, d.modelV);
    else
        mStr = "";
    end
    dStr = sprintf1(d.fmtStr, d.dataV)
    return "$(d.name): $mStr  d: $dStr"
end




# ---------------