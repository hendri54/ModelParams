# This effectively hard-wires the name of the ParamVector! +++
Lazy.@forward ModelSwitches.pvec (
    is_calibrated, calibrate!, fix!, param_value, param_default_value, retrieve
    );

# Default: ModelObjects store Params in ParamVector
param_loc(o :: ModelObject) = ParamsInVector();

has_pvector(switches :: ModelSwitches) = false;

function get_pvector(switches :: ModelSwitches)
    if has_pvector(switches)
        return switches.pvec;
    else
        return nothing;
    end
end


"""
	$(SIGNATURES)

Does object contain a `ParamVector`. Override for user defined types.
By default, ModelObjects are assumed to have `ParamVector`s.
"""
has_pvector(o :: ModelObject) = true;
has_pvector(o) = false;

function ModelObjectsLH.get_object_id(switches :: ModelSwitches)
    if has_pvector(switches)
        return get_object_id(get_pvector(switches))
    else
        return nothing
    end
end


"""
	$(SIGNATURES)

Retrieve the switches that govern the `ModelObject`'s behavior. Nothing if not found.
"""
function get_switches(o :: ModelObject)
    if isdefined(o, :switches)
        return o.switches;
    else
        return nothing;
    end
end
get_switches(o) = nothing;

has_switches(o) = !isnothing(get_switches(o));


"""
	$(SIGNATURES)

Find the ParamVector in a `ModelObject`. Return empty if not found.
Override for user types.
"""
function get_pvector(o)
    # Try the default field
    if has_pvector(o)  &&  isdefined(o, :pvec)
        pvec = o.pvec;
    elseif has_pvector(get_switches(o))
        pvec = get_switches(o).pvec;
    else
        pvec = ParamVector(o.objId);
    end
    return pvec :: ParamVector
end


"""
	$(SIGNATURES)

Retrieve a `Param` from the object's *own* `ParamVector`.

Efficiency: If `Param` stored directly in `ModelObject`, use getproperty. +++
"""
function retrieve(o, pName :: Symbol)
    return retrieve(param_loc(o), o, pName);
end

retrieve(::ParamsInObject, o, pName :: Symbol) = getfield(o, pName);
retrieve(::ParamsInVector, o, pName :: Symbol) = retrieve(get_pvector(o), pName);


# Code permits objects without ParamVector or child objects
function validate(o :: T1) where T1 <: ModelObject
    isValid = true;
    if !isa(get_object_id(o), ObjectId)
        @warn "Invalid ObjectId"
        isValid = false;
    end
    if has_pvector(o)
        if !isa(get_pvector(o), ParamVector)
            @warn "Invalid ParamVector"
            isValid = false;
        end
    end
    return isValid
end

function validate_all_params(o :: ModelObject; silent = true)
    return validate_pvec(collect_pvectors(o); silent);
end



## -----------  Check that params are consistent with `ParamVector`s

function check_param_values(x :: ModelObject, isCalibrated :: Bool)
    isValid = true;
    for o in collect_model_objects(x)
        if !check_own_param_values(o, get_pvector(o), isCalibrated);
            isValid = false;
        end
    end
    return isValid
end

check_calibrated_params(x :: ModelObject) = check_param_values(x, true);
check_fixed_params(x :: ModelObject) = check_param_values(x, false);


"""
    $(SIGNATURES)

Check that param vector values are consistent with object values.
Does not reach into child objects.
"""
function check_own_param_values(x :: ModelObject, pvec, isCalibrated :: Bool)
    pList = calibrated_params(pvec; isCalibrated);
    valid = true;
    for p in pList
        valid = valid  &&  check_own_param_value(x, p, isCalibrated);
    end
    return valid
end

function check_own_param_value(x, p, isCalibrated)
    pName = name(p);
    if isCalibrated
        pValue = calibrated_value(p);
    else
        pValue = default_value(p);
    end
    isValid = (calibrated_value(x, pName) ≈ pValue);
    if !isValid
        propValue = calibrated_value(x, pName);
        @warn "Invalid value: $pName: $pValue vs. $propValue";
    end
    return isValid
end


"""
	$(SIGNATURES)

Check that calibrated param vector values are consistent with object values.
Does not reach into child objects.   
"""
check_own_calibrated_params(x :: ModelObject, pvec) = 
    check_own_param_values(x, pvec, true);

"""
    $(SIGNATURES)

Check that all fixed parameters have the correct values
Does not reach into child objects.
"""
check_own_fixed_params(x :: ModelObject, pvec) =
    check_own_param_values(x, pvec, false);


"""
	$(SIGNATURES)

Do two model objects have the same calibrated parameters?
Includes child objects.
This is mainly useful for testing (e.g., loading parameters).
"""
function params_equal(x1 :: ModelObject, x2 :: ModelObject)
    guess1 = make_guess(x1);
    guess2 = make_guess(x2);
    v1 = get_values(x1, guess1);
    v2 = get_values(x2, guess2);
    return isapprox(v1, v2; atol = 1e-6)
end


## -----------  Change values

"""
	$(SIGNATURES)

Change value of a field in a `ModelObject` and its `ParamVector`.

# Example
```julia
change_value!(mObj, :utilityFunction, :sigma, 2.0);
get_value(mObj, :utilityFunction, :sigma) ≈ 2.0
```
"""
function change_value!(x :: ModelObject, oName :: Symbol, pName :: Symbol,  newValue)
    obj = find_only_object(x, oName);
    return change_own_value!(obj, pName, newValue);
end

change_own_value!(obj :: ModelObject, pName :: Symbol, newValue) = 
    change_own_value!(param_loc(obj), obj, pName, newValue);

function change_own_value!(::ParamsInObject, x :: ModelObject, pName :: Symbol, newValue)
    return set_calibrated_value!(x, pName, newValue);
end

function change_own_value!(::ParamsInVector, obj :: ModelObject, pName :: Symbol, newValue)
    # Set in the object itself
    setfield!(obj, pName, newValue);
    # Set in ParamVector
    pvec = get_pvector(obj);
    @assert length(pvec) > 0  "No ParamVector in $obj / $pName";
    oldValue = change_value!(pvec, pName, newValue);
    # # Set value in object as well, but only if the `Param` isn't 
    # # directly stored in the object.
    # if !isa(getfield(obj, pName), AbstractParam)
    #     setfield!(obj, pName, deepcopy(newValue));

    # end
    return oldValue    
end

calibrated_value(x :: ModelObject, pName :: Symbol) = 
    calibrated_value(param_loc(x), x, pName);

calibrated_value(::ParamsInObject, x :: ModelObject, pName :: Symbol) = 
    calibrated_value(getfield(x, pName));

# Assumes a one-to-one mapping between calibrated params and those stored in
# object. 
calibrated_value(::ParamsInVector, x :: ModelObject, pName :: Symbol) = 
    getfield(x, pName);




"""
	$(SIGNATURES)

Value of a parameter in the ModelObject itself. User facing.
Takes the value out of an `AbstractParam` if necessary.
"""
function pvalue(x :: ModelObject, pName :: Symbol)
    return pvalue(param_loc(x), x, pName);
    # v = getfield(x, pName);
    # (v isa AbstractParam)  ?  (vValue = value(v))  :  (vValue = v);
    # return vValue
end

pvalue(::ParamsInObject, x :: ModelObject, pName :: Symbol) = 
    pvalue(getfield(x, pName));

pvalue(::ParamsInVector, x :: ModelObject, pName :: Symbol) = 
    getfield(x, pName);


"""
	$(SIGNATURES)

Set parameter value in the object itself (if it is stored there).
Otherwise, set it in matching `Param`. The end result is that 
`pvalue(x, pName) == newValue`.

Does not change value in `ParamVector` if that's where values are stored.
Used to set own parameters from Dict and similar.
`change_value!` changes the `Param` and the value in the object (if they are distinct).
"""
function set_calibrated_value!(x :: ModelObject, pName :: Symbol, newValue)
    set_calibrated_value!(param_loc(x), x, pName, newValue);
end

set_calibrated_value!(::ParamsInObject, x :: ModelObject, pName :: Symbol, newValue) = 
    set_calibrated_value!(getfield(x, pName), newValue);

function set_calibrated_value!(::ParamsInVector, x :: ModelObject, 
    pName :: Symbol, newValue)
    @assert !isa(getfield(x, pName), AbstractParam)  "$pName in $x is an AbstractParam. Set correct param_loc";
    setfield!(x, pName, newValue);
end


"""
	$(SIGNATURES)

Retrieve a parameter value in a `ModelObject` and its children. User facing.
"""
function get_value(x :: ModelObject, oName :: Symbol, pName :: Symbol)
    # @show x, oName
    obj = find_only_object(x, oName);
    pvec = get_pvector(obj);
    @assert length(pvec) > 0  "No or empty ParamVector in $oName";
    @assert param_exists(pvec, pName)  "$pName not found";
    p = retrieve(pvec, pName);
    return pvalue(p)
end

## Set fields in struct from param vector (using values, not defaults)
# Does not reach into child objects.
function set_own_values_from_pvec!(x :: ModelObject, isCalibrated :: Bool;
    alwaysUseDefaultValue = false)

    pvec = get_pvector(x);
    pList = calibrated_params(pvec; isCalibrated);
    for p in pList
        set_own_value_from_param!(x, p; alwaysUseDefaultValue);
    end
    return nothing
end

# Ignores if no corresponding property exists in x.
function set_own_value_from_param!(x :: ModelObject, p :: AbstractParam;
    alwaysUseDefaultValue = false)

    pName = name(p);
    if pName ∈ propertynames(x)
        if is_calibrated(p)  &&  (!alwaysUseDefaultValue)
            val = calibrated_value(p; returnIfFixed = true);
        else
            val = default_value(p);
        end
        set_calibrated_value!(x, pName, val);
    end
end


"""
	$(SIGNATURES)

Set fields in a struct from a Dict{Symbol, Any}.
Does not change `ParamVector` inside `x` (if any).
Does not change child objects.
"""
function set_own_values_from_dict!(x :: ModelObject,  d :: D1) where D1 <: AbstractDict
    for (k, val) in d
        if k ∈ propertynames(x)
            set_calibrated_value!(x, k, val);
        else
            @warn "Field $k not found";
        end
    end
    return nothing
end


## Set default values from param vector
# Typically for non-calibrated parameters
function set_own_default_values!(x :: ModelObject, isCalibrated :: Bool)
    set_own_values_from_pvec!(x, isCalibrated; alwaysUseDefaultValue = true);
    return nothing
end

"""
	$(SIGNATURES)

Sync all values from all objects' param vectors into objects.
"""
function sync_values!(x :: ModelObject)
    for o in collect_model_objects(x)
        if has_pvector(o)
            sync_own_values!(o);
        end
    end
end


"""
    $(SIGNATURES)

Sync all values from object's param vector into object.
"""
function sync_own_values!(x :: ModelObject)
    # Set calibrated parameters
    set_own_values_from_pvec!(x, true);
    # Set fixed parameters
    set_own_default_values!(x, false);
end


"""
	$(SIGNATURES)

Set all parameters to calibrated or fixed. Useful for experiments that calibrate only select parameters. Recurses into child objects.
"""
function set_calibration_status_all_params!(x :: ModelObject, isCalibrated :: Bool)
    pvecV = collect_pvectors(x);
    for (_, pvec) in pvecV
        set_calibration_status_all_params!(pvec, isCalibrated);
    end
end


"""
	$(SIGNATURES)

Set default values for all parameters to values. 
Useful for fixing parameters at previously calibrated values.
"""
function set_default_values_all_params!(x :: ModelObject)
    pvecV = collect_pvectors(x);
    for (_, pvec) in pvecV
        set_default_values_all_params!(pvec);
    end
end


"""
	$(SIGNATURES)

Return all `Param`s in a `ModelObject`. Optionally filtered by calibration status.
Returns `Vector{AbstractParam}`. Note that names of parameters may not be unique.
"""
function all_params(x :: ModelObject; isCalibrated = nothing)
    pvecV = collect_pvectors(x);
    pList = Vector{AbstractParam}();
    for (_, pvec) in pvecV
        pvecList = all_params(pvec; isCalibrated);
        isempty(pvecList)  ||  append!(pList, pvecList);
    end
    return pList
end


"""
	$(SIGNATURES)

Report parameters that differ across objects. Returns a table with columns:
- objectId
- param name
- values in both objects

Can be written to various formats using `pretty_table`.

Currently ignores values in o2 that do not exist in o1.
Size differences in parameters are permitted.
"""
function report_param_differences(o1, o2; sorted = true)
    pvec1V = collect_pvectors(o1);
    pvec2V = collect_pvectors(o2);

    tbM = Matrix{String}(undef, 0, 4);
    vDiffV = Vector{Float64}(undef, 0);
    for (objId, pvec1) in pvec1V
        if has_pvector(pvec2V, objId)
            idStr = repeat("  ", n_parents(objId)) * string(own_name(objId));
            pvec2 = find_pvector(pvec2V, objId);

            for p1 in pvec1
                pName = name(p1);
                v1 = pvalue(p1);
                rowV = nothing;
                vDiff = 0.0;

                if param_exists(pvec2, pName)
                    p2 = retrieve(pvec2, pName);
                    v2 = pvalue(p2);
                    vDiff = value_diff(v1, v2);
                    if (size(v1) != size(v2))  ||  (!isapprox(v1, v2; atol = 1e-3))
                        rowV = param_diff_row(idStr, pName, p1.description, v1, v2);
                    end
                else
                    rowV = param_diff_row(idStr, pName, p1.description, v1, "missing");
                    vDiff = 1e8;
                end
                if !isnothing(rowV)
                    tbM = vcat(tbM, rowV);
                    push!(vDiffV, vDiff);
                end
            end
        end
    end
    if sorted  &&  !isempty(vDiffV)
        tbM = tbM[sortperm(vDiffV; rev = true), :];
    end
    return tbM
end

function value_diff(v1 :: T1, v2 :: T1) where T1 <: Number
    return abs(v2 - v1) / max(abs(v1), 0.01);
end

function value_diff(v1 :: Vector{T1}, v2 :: Vector{T1}) where T1 <: Number
    if size(v1) != size(v2)
        return 1e8;
    else
        return sum(abs.(v2 .- v1) ./ max.(abs.(v1), 1.0)) / length(v1);
    end
end

value_diff(v1, v2) = 1e8;

function param_diff_row(idStr, pName, pDescr, v1, v2)
    # sV = fill(" ", 1, 3);
    descr = pDescr[1 : min(15, length(pDescr))];
    sV = ["$idStr / $pName"  descr  formatted_value(v1)  formatted_value(v2)];
    return sV
end


"""
	$(SIGNATURES)

Compare parameters across objects. Optionally filtered on calibration status.
Returns list of 
- missing on o1
- missing in o2
- different between the objects

Each is a `Dict` that contains another `Dict` for each `ObjectId` with differences.
"""
function compare_params(o1, o2; ignoreCalibrationStatus :: Bool = true)
    pvec1V = collect_pvectors(o1);
    pvec2V = collect_pvectors(o2);

    pMiss1 = Dict{ObjectId, Any}();
    pMiss2 = Dict{ObjectId, Any}();
    pDiff = Dict{ObjectId, Any}();
    for (objId, pvec1) in pvec1V
        if has_pvector(pvec2V, objId)
            pvec2 = find_pvector(pvec2V, objId);
            miss1, miss2, dif = compare_params(pvec1, pvec2; ignoreCalibrationStatus);
            isempty(miss1)  ||  (pMiss1[objId] = miss1);
            isempty(miss2)  ||  (pMiss2[objId] = miss2);
            isempty(dif)    ||  (pDiff[objId] = dif);
        else
            @warn "ParamVector $objId not found."
        end
    end

    return pMiss1, pMiss2, pDiff
end


"""
	$(SIGNATURES)

Dict with parameter info for an entire `ModelObject` and its children.
"""
function make_dict(o :: ModelObject, isCalibrated :: Bool)
    pvecV = collect_pvectors(o);
    return make_dict(pvecV; isCalibrated, valueType = :calibratedValue);
end


"""
	$(SIGNATURES)

Check that param values match across two model objects (including children). 
Allow for differences in the objects listed by own name (Symbol) in `differentIdV`.
"""
function check_params_match(m1, m2, 
    allowedIdV :: AbstractVector{ObjectId};
    ignoreCalibrationStatus = true)
    
    isValid = true;
    miss1, miss2, pDiff = compare_params(m1, m2; ignoreCalibrationStatus);
    if !isempty(miss1)
        isValid = false;
        @warn "Missing params in m1:  $miss1";
    end
    if !isempty(miss2)
        isValid = false;
        @warn "Missing params in m2:  $miss2";
    end

    # Check that differences occur only in permitted objects.
    diffIdV = collect(keys(pDiff));
    if !isempty(diffIdV)
        for oId in diffIdV
            if !any_isequal(oId, allowedIdV)
                isValid = false;
                @warn "Param differences in $oId";
            end
        end
    end
    return isValid
end

# function collect_object_ids(m, differentIdV)
#     return [get_object_id(find_only_object(m, oName))  
#         for oName in differentIdV];
#     # for oName in differentIdV
#     #     o = find_object(m, oName);
#     #     if isempty(o)
#     #         isValid = false;
#     #         @warn "Object $oName not found";
#     #     else 
#     #         oId = get_object_id(o);
#     #     end
#     # end    
# end

# Because broadcasting ObjectId not implemented yet.
function any_isequal(oId, oIdV)
    found = false;
    for oId2 in oIdV
        if isequal(oId, oId2)
            found = true;
            break;
        end
    end
    return found
end


# -----------------