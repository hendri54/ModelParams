Base.size(d :: PenaltyDeviation) = Base.size(get_model_values(d));

get_data_values(d :: PenaltyDeviation) = nothing;
set_model_values(d :: PenaltyDeviation, modelV) = (d.modelV = modelV);


"""
    $(SIGNATURES)

Scalar deviation from one Deviation object.

Optionally includes `scalarWt` factor.
"""
function scalar_dev(d :: PenaltyDeviation; inclScalarWt :: Bool = true)
    scalarDev = d.scalarDevFct(d.modelV);
    if inclScalarWt
        scalarDev *= d.scalarWt;
    end
    scalarStr = sprintf1("%.2f", scalarDev);

    return scalarDev :: DevType, scalarStr
end


"""
	$(SIGNATURES)

Show a bounds deviation. As a table.
"""
function penalty_show_fct(d :: PenaltyDeviation; showModel :: Bool = true, fPath :: String = "")
    io = open_show_path(d, fPath = fPath);

    println(io, "$(d.name): ")
    println(io, get_model_values(d));

    close_show_path(d, io);
    return nothing
end

Base.show(io :: IO, p :: PenaltyDeviation) = Base.print(io, "Penalty deviation")

# ----------------