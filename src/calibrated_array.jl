export CalibratedArraySwitches, CalibratedArray
export validate_ca

function CalibratedArraySwitches(objId :: ObjectId,
    defaultValueM :: Array{T1, N}, lbM :: Array{T1, N}, ubM :: Array{T1, N}, 
    isCalInM) where {T1, N}

    isCalM = Array{Bool, N}(isCalInM);
    @assert size(defaultValueM) == size(lbM) == size(ubM) == size(isCalM);

    # handle the case where all values are fixed +++++
    valueV = defaultValueM[isCalM];
    p = Param(:calValueV, "Calibrated values", "calValueV", 
        valueV, valueV, lbM[isCalM], ubM[isCalM], true);
    pvec = ParamVector(objId, [p]);
    return CalibratedArraySwitches(pvec, defaultValueM, lbM, ubM, isCalM)
end

function CalibratedArray(switches :: CalibratedArraySwitches{T1, N}) where {T1, N}
    calValueV = switches.defaultValueM[switches.isCalM];
    valueM = copy(switches.defaultValueM);
    objId = get_object_id(switches);
    return CalibratedArray(objId, switches, calValueV, valueM)
end


## -------------  Basics

Lazy.@forward CalibratedArray.switches (
    Base.size,
    get_pvector
);

ModelObjectsLH.get_object_id(switches :: CalibratedArraySwitches{T1, N}) where {T1, N} = get_object_id(switches.pvec);
get_pvector(switches :: CalibratedArraySwitches{T1, N}) where {T1, N} =
    switches.pvec;
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
    idxV = map_indices(ca);
    calValueV = ca.valueM[idxV];
    isValid = isapprox(calValueV, ca.calValueV);

    pvec = get_pvector(ca);
    isValid = isValid  &&  isapprox(calValueV, param_value(pvec, :calValueV));

    isValid = isValid  &&  check_fixed_values(ca);
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
    idxV = zeros(Int, nCal);
    j2 = 0;
    for (j, isCal) in enumerate(ca.switches.isCalM)
        if isCal
            j2 += 1;
            idxV[j2] = j;
        end
    end
    @assert j2 == length(ca.calValueV);
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