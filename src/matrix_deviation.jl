"""
    $(SIGNATURES)

Empty deviation. Mainly as return object when no match is found in DevVector
"""
function empty_deviation(F1 = Float64)
    return Deviation{F1}(name = :empty)
end


# Do not check that sizes of modelV and dataV match because of `idxV`.
function validate_deviation(d :: Deviation{F1}) where F1
    isValid = true;
    if !all(isfinite.(d.modelV))
        @warn "Model values not finite for $d: $(d.modelV)"
        isValid = false;
    end
    if !all(isfinite.(d.dataV))
        @warn "Data values not finite for $d: $(d.dataV)"
        isValid = false;
    end
    if !all(isfinite.(d.wtV))
        @warn "Weights not finite for $d: $(d.wtV)"
        isValid = false;
    end
    isValid = isValid  &&  (ndims(d.modelV) == ndims(d.dataV))
    return isValid
end


function get_model_values(d :: Deviation{F1}; matchData :: Bool = false) where F1
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


function set_model_values(d :: Deviation{F1}, modelV) where F1
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
function scalar_dev(d :: Deviation{F1}; inclScalarWt :: Bool = true) where F1
    modelV = get_model_values(d; matchData = true);
    @assert size(modelV) == size(get_data_values(d))

    devV = d.wtV .* abs.(modelV .- get_data_values(d));
    scalarDev = sum(devV);
    if inclScalarWt
        scalarDev *= d.scalarWt;
    end
    scalarStr = sprintf1(d.fmtStr, scalarDev);
    @assert scalarDev >= zero(F1)  "Negative deviation for $d: $scalarDev"
    return scalarDev, scalarStr
end


## -----------  Show

Base.show(io :: IO, d :: Deviation{F1}) where F1 = 
    Base.print(io, "$(name(d)):  ", short_description(d));



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