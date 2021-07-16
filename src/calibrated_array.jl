export CalibratedArraySwitches, CalibratedArray
export validate_ca

function CalibratedArraySwitches(objId :: ObjectId,
    defaultValueM :: Array{T1, N}, lbM :: Array{T1, N}, ubM :: Array{T1, N}, 
    isCalInM) where {T1, N}

    isCalM = Array{Bool, N}(isCalInM);
    @assert size(defaultValueM) == size(lbM) == size(ubM) == size(isCalM);

    doCal = true;
    valueV = defaultValueM[isCalM];
    if all(.!isCalM)
        doCal = false;
    end
    p = Param(:calValueV, "Calibrated values", "calValueV", 
        valueV, valueV, lbM[isCalM], ubM[isCalM], doCal);
    pvec = ParamVector(objId, [p]);
    return CalibratedArraySwitches(pvec, defaultValueM, lbM, ubM, isCalM)
end


"""
	$(SIGNATURES)

Array with a mix of calibrated and fixed elements.
"""
function CalibratedArray(switches :: CalibratedArraySwitches{T1, N}) where {T1, N}
    calValueV = switches.defaultValueM[switches.isCalM];
    valueM = copy(switches.defaultValueM);
    objId = get_object_id(switches);
    return CalibratedArray(objId, switches, calValueV, valueM)
end


function make_test_calibrated_array_switches(N :: Integer; allFixed = false)
    rng = MersenneTwister(23);
    objId = ObjectId(:test);
    sizeV = 2 : (1 + N);
    sz = (sizeV..., );

    T1 = Float64;
    defaultValueM = randn(rng, T1, sz);
    lbM = defaultValueM .- one(T1);
    ubM = defaultValueM .+ one(T1);
    if allFixed
        isCalM = trues(size(lbM));
    else
        isCalM = defaultValueM .> 0.0;
    end

    switches = CalibratedArraySwitches(objId, defaultValueM, lbM, ubM, isCalM);
    return switches
end


## -------------  Basics

Lazy.@forward CalibratedArray.switches (
    Base.size
);

has_pvector(::CalibratedArraySwitches{T1, N}) where {T1, N} = true;

# ModelObjectsLH.get_object_id(switches :: CalibratedArraySwitches{T1, N}) where {T1, N} = get_object_id(switches.pvec);
# get_pvector(switches :: CalibratedArraySwitches{T1, N}) where {T1, N} =
#     switches.pvec;
Base.size(switches :: CalibratedArraySwitches{T1, N}) where {T1, N} = 
    size(switches.defaultValueM);


## --------  Validate

function validate_ca(ca :: CalibratedArray{T1, N}) where {T1, N}
    switches = ca.switches;
    isValid = true;
    isValid = isValid  && (size(switches.defaultValueM) == size(switches.lbM) == size(switches.ubM) == size(switches.isCalM));
    isValid = isValid  &&  check_values(ca);
    return isValid
end

function check_values(ca :: CalibratedArray{T1, N}) where {T1, N}
    isValid = check_calibrated_values(ca)  &&  check_fixed_values(ca);
    return isValid
end

function check_calibrated_values(ca :: CalibratedArray{T1, N}) where {T1, N}
    idxV = map_indices(ca);
    isempty(idxV)  &&  return true;

    calValueV = ca.valueM[idxV];
    isValid = isapprox(calValueV, ca.calValueV);

    pvec = get_pvector(ca);
    isValid = isValid  &&  isapprox(calValueV, param_value(pvec, :calValueV));
    return isValid
end


function check_fixed_values(ca :: CalibratedArray{T1, N}) where {T1, N}
    valueM = values(ca);
    isValid = true;
    for (j, isCal) in enumerate(ca.switches.isCalM)
        if !isCal
            isValid = isValid && (valueM[j] ≈ ca.switches.defaultValueM[j]);
        end
    end
    return isValid
end


## ------------  Retrieve

# change +++: retrieve with array interface; without allocating
function values(ca :: CalibratedArray{T1, N}) where {T1, N}
    update_values!(ca);
    return ca.valueM;
end

# Linear index into arrays for each calibrated value.
function map_indices(ca :: CalibratedArray{T1, N}) where {T1, N}
    nCal = sum(ca.switches.isCalM);
    if nCal > 0
        idxV = zeros(Int, nCal);
        j2 = 0;
        for (j, isCal) in enumerate(ca.switches.isCalM)
            if isCal
                j2 += 1;
                idxV[j2] = j;
            end
        end
        @assert j2 == length(ca.calValueV);
    else
        idxV = Vector{Int}();
    end
    return idxV
end

# Update calibrated array values in object from calibrated vector values.
function update_values!(ca :: CalibratedArray{T1, N}) where {T1, N}
    ca.valueM .= ca.switches.defaultValueM;
    idxV = map_indices(ca);
    for (j, idx) in enumerate(idxV)
        ca.valueM[idx] = ca.calValueV[j];
    end
end

# ---------------