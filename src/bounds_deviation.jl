Base.size(d :: BoundsDeviation) = Base.size(lbounds(d));

get_data_values(d :: BoundsDeviation) = nothing;
lbounds(d :: BoundsDeviation) = d.lbV;
ubounds(d :: BoundsDeviation) = d.ubV;
inside_bounds(d :: BoundsDeviation) = all(d.ubV .>= d.modelV .>= d.lbV);
set_model_values(d :: BoundsDeviation, modelV) = (d.modelV = deepcopy(modelV));


"""
    $(SIGNATURES)

Scalar deviation from one Deviation object.

Optionally includes `scalarWt` factor.
"""
function scalar_dev(d :: BoundsDeviation{F1}; inclScalarWt :: Bool = true) where F1
    if inside_bounds(d)
        scalarDev = zero(F1);
    else
        modelV = get_model_values(d);
        devV = d.wtV .* max.(zero(F1), modelV .- ubounds(d)) .+
            d.wtV .* max.(zero(F1), lbounds(d) .- modelV);
        scalarDev = sum(devV);
        if inclScalarWt
            scalarDev *= d.scalarWt;
        end
    end
    scalarStr = sprintf1(d.fmtStr, scalarDev);

    return scalarDev, scalarStr
end


"""
	$(SIGNATURES)

Show a bounds deviation. As a table.
"""
function bounds_show_fct(d :: BoundsDeviation{F1}; showModel :: Bool = true, fPath :: String = "") where F1
    io = open_show_path(d, fPath = fPath);

    # Dimensions of data matrix
    lbV = lbounds(d);
    ubV = ubounds(d);
    modelV = get_model_values(d);
    nd = ndims(lbV);
    if nd > 2
        @warn "Showing deviation not implemented for ndims = $nd"
    elseif nd == 2
        (nr, nc) = size(lbV);
    elseif nd == 1
        nr = length(lbV);
        nc = 1;
    else
        error("Empty deviation")
    end

    println(io, "$(d.name):  Lb / Model / Ub")
    for ir = 1 : nr
        print(io, "\t $ir: ");
        for ic = 1 : nc
            if showModel
                mStr = sprintf1(d.fmtStr, modelV[ir, ic]);
            else
                mStr = "  --  ";
            end
            lbStr = sprintf1(d.fmtStr, lbV[ir, ic]);
            ubStr = sprintf1(d.fmtStr, ubV[ir, ic]);
            print(io, "\t $lbStr / $mStr / $ubStr");
        end
        print(io, "\n");
    end

    close_show_path(d, io);
    return nothing
end


# ----------------