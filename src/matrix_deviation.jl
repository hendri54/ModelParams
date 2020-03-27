"""
    empty_deviation()

Empty deviation. Mainly as return object when no match is found in DevVector
"""
function empty_deviation()
    return Deviation(name = :empty)
end


function get_model_values(d :: Deviation; matchData :: Bool = false)
    if matchData  &&  !isempty(d.idxV)
        modelV = d.modelV[d.idxV...];
    else
        modelV = d.modelV;
    end
    if matchData  ||  isempty(d.idxV)
        @assert size(modelV) == size(get_data_values(d))
    end
    return deepcopy(modelV)
end


"""
	set_model_values

Set model values in an existing deviation.
"""
function set_model_values(d :: Deviation, modelV)
    dataV = get_data_values(d);
    if typeof(modelV) != typeof(dataV)  
        println(modelV);
        println(dataV);
        error("Type mismatch in $(d.name): $(typeof(modelV)) vs $(typeof(dataV))");
    end
    if isempty(d.idxV)
        # Size can be different in general
        @assert size(modelV) == size(dataV)  "Size mismatch $(d.name): $(size(modelV)) vs $(size(dataV))"
    end
    @assert ndims(modelV) == ndims(dataV)  "Dimension mismatch $(d.name):  $(ndims(modelV)) vs $(ndims(dataV))"
    d.modelV = deepcopy(modelV);
    return nothing
end


"""
    $(SIGNATURES)

Scalar deviation from one Deviation object.

Optionally includes `scalarWt` factor.
"""
function scalar_dev(d :: Deviation; inclScalarWt :: Bool = true)
    modelV = get_model_values(d; matchData = true);
    @assert size(modelV) == size(get_data_values(d))

    devV = d.wtV .* abs.(modelV .- get_data_values(d));
    scalarDev = sum(devV);
    if inclScalarWt
        scalarDev *= d.scalarWt;
    end
    scalarStr = sprintf1(d.fmtStr, scalarDev);

    return scalarDev :: DevType, scalarStr
end


"""
	$(SIGNATURES)

Show a vector / matrix deviation
"""
function deviation_show_fct(d :: Deviation; showModel :: Bool = true, fPath :: String = "")
    io = open_show_path(d, fPath = fPath);

    # Dimensions of data matrix
    dataV = get_data_values(d);
    modelV = get_model_values(d; matchData = true);
    nd = ndims(dataV);
    if nd > 2
        @warn "Showing deviation not implemented for ndims = $nd"
    elseif nd == 2
        (nr, nc) = size(dataV);
    elseif nd == 1
        nr = length(dataV);
        nc = 1;
    else
        error("Empty deviation")
    end

    println(io, "$(d.name):  Model / Data")
    for ir = 1 : nr
        print(io, "\t $ir: ");
        for ic = 1 : nc
            if showModel
                mStr = sprintf1(d.fmtStr, modelV[ir, ic]);
            else
                mStr = "  --  ";
            end
            dStr = sprintf1(d.fmtStr, dataV[ir, ic]);
            print(io, "\t $mStr / $dStr");
        end
        print(io, "\n");
    end

    close_show_path(d, io);
    return nothing
end


# ----------------