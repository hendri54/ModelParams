# Code that deals with objects and child objects.

"""
	$(SIGNATURES)

Collect all `ParamVector`s in an object and its child objects.
"""
function collect_pvectors(o :: ModelObject)
    pvecV = Vector{ParamVector}();
    objV = collect_model_objects(o);
    if !isempty(objV)
        for i1 = 1 : length(objV)
            push!(pvecV, get_pvector(objV[i1]));
        end
    end
    return pvecV :: Vector{ParamVector}
end


## --------------  Vectors and Dicts

"""
    $(SIGNATURES)

Make vector from a list of param vectors.
Output contains values, lower bounds, upper bounds.
"""
function make_vector(pvv :: Vector{ParamVector}, isCalibrated :: Bool)
    outV = Vector{ValueType}();
    lbV = Vector{ValueType}();
    ubV = Vector{ValueType}();
    pNameV = Vector{Symbol}();
    for i1 = 1 : length(pvv)
        vVec = make_vector(pvv[i1], isCalibrated);
        append!(outV, values(vVec));
        append!(lbV, lb(vVec));
        append!(ubV, ub(vVec));
        append!(pNameV, pnames(vVec));
    end
    vv = ValueVector(outV, lbV, ubV, pNameV);
    return vv
end


"""
	$(SIGNATURES)

Make a `Vector{ParamVector}` into a `Dict{String, Dict{Symbol, Any}}`.
Each entry is one `ParamVector`. 
They key is the `ObjectId` of each `ParamVector` made into a `String`. Such as "parent > child > grandchild[2, 1]".
The value is the `ParamVector` made into a Dict.

This is a format that can be saved without using user defined types. There is hope this can be serialized.
"""
function make_dict(pvv :: Vector{ParamVector}; isCalibrated :: Bool = true)
    n = length(pvv);
    if n < 1
        return nothing
    end

    d = nothing;
    for j = 1 : n
        pv = pvv[j];
        key = make_string(get_object_id(pv));
        pd = make_dict(pv, isCalibrated);
        if j == 1
            d = Dict([key => pd]);
        else
            push!(d, key => pd);
        end
    end

    return d
end


## -------------  Setting values


"""
	$(SIGNATURES)

Set model values from `Dict{String, Dict}` generated by `make_dict`.
Includes child objects.
"""
function set_values_from_dicts!(x :: ModelObject,  pvDict :: D1; isCalibrated :: Bool = true) where D1 <: AbstractDict

    # Collect all model objects
    mObjV = collect_model_objects(x);

    # Loop over `ParamVector`s, represented as Dicts
    # `nameStr` is the `ObjectId` converted into a `String`
    # `pd` is the `ParamVector` converted into a `Dict`
    for (nameStr,  pd) in pvDict
        # Make string into ObjectId. Allow for `nameStr` to be something that can be made into `String`
        oId = make_object_id(string(nameStr));
        # Find the matching model object
        obj = find_object(x, oId);
        if !isnothing(obj)
            set_values_from_dict!(obj.pvec, pd);
            set_own_values_from_pvec!(obj, isCalibrated);
        end
    end
    return nothing
end


"""
	$(SIGNATURES)

Copy all values from a vector of `ParamVector` into an object, including child objects.
Only changes values that are `isCalibrated` in object and `v`.
"""
function set_values_from_pvectors!(x :: ModelObject, v :: Vector{ParamVector}, isCalibrated :: Bool)
    # Collect all model objects
    mObjV = collect_model_objects(x);

    # Loop over `ParamVector`s
    for pvec in v
        # Find the matching model object
        obj = find_object(x, pvec.objId);
        # show(obj)
        if !isnothing(obj)
            set_own_values_from_pvec!(obj.pvec, pvec, isCalibrated);
            set_own_values_from_pvec!(obj, isCalibrated);
        end
    end
    return nothing
end


"""
    $(SIGNATURES)

Copy values from vector into param vector and object.
Calibrated parameters.
Also ensures that fixed parameters are set according to `ParamVector`.
Uses the values in `vAll` starting from (optional) `startIdx`.
Returns index of last value used.
Order in `vAll` must match order in `pvec`. E.g., because `vAll` is generated by `make_vector`.
"""
function sync_own_from_vector!(x :: ModelObject, vAll :: ValueVector;
    startIdx = 1)
    
    pvec = get_pvector(x);
    d11, idxEnd = vector_to_dict(pvec, vAll, true; startIdx = startIdx);
    set_values_from_dict!(pvec, d11);
    sync_own_values!(x);
    return idxEnd
end


"""
    $(SIGNATURES)

Copy values from a *vector* of `ParamVector` into a *vector* of `ModelObject`s.
The order of the objects must match the order of the `ParamVector`s.
The order of the values in `vAllInV` must match the order of `ParamVector`s.
Returns `true` if all values used; `false` otherwise.
Also ensures that all fixed parameters match `ParamVector`.
"""
function sync_from_vector!(xV :: Vector, vAll :: ValueVector)
    startIdx = 1;
    for i1 = 1 : length(xV)
        # check that ParamVector matches model object
        # @assert check_match(pvecV[i1], xV[i1].objId);
        o = xV[i1];
        idxLast = sync_own_from_vector!(o, vAll; startIdx = startIdx);
        @assert check_calibrated_params(o, get_pvector(o))
        @assert check_fixed_params(o, get_pvector(o))
        startIdx = idxLast + 1;
    end

    if startIdx == length(vAll) + 1
        success = true;
    else
        success = false;
        @warn "Not all values used: $(startIdx - 1)  vs  $(length(vAll))"
    end
    return success
end

# --------------