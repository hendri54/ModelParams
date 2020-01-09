## -------------  Info about `ModelObject`


# There is currently nothing to validate
# Code permits objects without ParamVector or child objects
function validate(m :: T1) where T1 <: ModelObject
    # @assert isa(m.hasParamVector, Bool)
    # @assert isa(get_child_objects(m), Vector)
    @assert isdefined(m, :objId)
    return nothing
end


"""
    $(SIGNATURES)

Collect all model objects inside an object. Only those that have a `pvector`.
Recursive. Also collects objects inside child objects and so on.
"""
function collect_model_objects(o :: T1) where T1 <: ModelObject
    outV = Vector{Any}();
    # nameV = Vector{Symbol}();
    if has_pvector(o)
        push!(outV, o);
        # push!(nameV, objName);
    end

    # Objects directly contained in `o`
    childObjV = get_child_objects(o);
    if !Base.isempty(childObjV)
        for i1 = 1 : length(childObjV)
            nestedObjV = collect_model_objects(childObjV[i1]);
            append!(outV, nestedObjV);
            # append!(nameV, nestedNameV);
        end
    end
    return outV :: Vector  # , nameV :: Vector{Symbol}
end


"""
    $(SIGNATURES)

Find the child objects inside a model object.
"""
function get_child_objects(o :: T1) where T1 <: ModelObject
    childV = Vector{Any}();
    # nameV = Vector{Symbol}();
    for pn in propertynames(o)
        obj = getproperty(o, pn);
        if isa(obj, Vector)
            if eltype(obj) <: ModelObject
                append!(childV, obj);
                # for i1 = 1 : length(obj)
                #     push!(nameV, Symbol("$pn$i1"));
                # end
            end
        else
            if typeof(obj) <: ModelObject
                push!(childV, obj);
                # push!(nameV, pn);
            end
        end
    end
    return childV :: Vector  # , nameV
end



"""
	$(SIGNATURES)

Find child object with a given `ObjectId`.
Returns `nothing` if not found.
"""
function find_object(o :: ModelObject, id :: ObjectId)
    objV = collect_model_objects(o);
    oOut = nothing;
    if !isempty(objV)
        for obj in objV
            if isequal(obj.objId, id)
                oOut = obj;
                break;
            end
        end
    end
    return oOut
end


## Find the ParamVector
function get_pvector(o :: T1) where T1 <: ModelObject
    found = false;
    pvec = ParamVector(o.objId);

    # Try the default field
    if isdefined(o, :pvec)
        if isa(o.pvec, ParamVector)
            pvec = o.pvec;
            found = true;
        end
    end

    if !found
        for pn = propertynames(o)
            obj = getproperty(o, pn);
            if isa(obj, ParamVector)
                pvec = obj;
                found = true;
                break;
            end
        end
    end
    return pvec :: ParamVector
end


## Does object contain ParamVector
function has_pvector(o :: T1) where T1 <: ModelObject
    return length(get_pvector(o)) > 0
end


function collect_pvectors(o :: T1) where T1 <: ModelObject
    objV = collect_model_objects(o);
    pvecV = Vector{ParamVector}();
    for i1 = 1 : length(objV)
        push!(pvecV, get_pvector(objV[i1]));
    end
    return pvecV :: Vector{ParamVector}
end


## -------------  Setting values


## Set fields in struct from param vector (using values, not defaults)
function set_values_from_pvec!(x :: ModelObject, isCalibrated :: Bool)
    pvec = get_pvector(x);
    d = make_dict(pvec, isCalibrated, true);
    set_values_from_dict!(x, d);
    return nothing
end


## Set default values from param vector
#Typically for non-calibrated parameters
function set_default_values!(x, isCalibrated :: Bool)
    pvec = get_pvector(x);
    # Last arg: use default values
    d = make_dict(pvec, isCalibrated, false);
    set_values_from_dict!(x, d);
    return nothing
end


## Set fields in a struct from a Dict{Symbol, Any}.
# Does not change `ParamVector` inside `x` (if any)
function set_values_from_dict!(x,  d :: Dict{Symbol, Any})
    for (k, val) in d
        if k ∈ propertynames(x)
            setfield!(x, k, val);
        else
            @warn "Field $k not found"
        end
    end
    return nothing
end

"""
	$(SIGNATURES)

Copy all values from a vector of `ParamVector` into an object, including child objects.
Only changes values that are `isCalibrated` in object and `v`.
"""
function set_values_from_pvectors!(x, v :: Vector{ParamVector}, isCalibrated :: Bool)
    # Collect all model objects
    mObjV = collect_model_objects(x);

    # Loop over `ParamVector`s
    for pvec in v
        # Find the matching model object
        obj = find_object(x, pvec.objId);
        # show(obj)
        if !isnothing(obj)
            set_values_from_pvec!(obj.pvec, pvec, isCalibrated);
            set_values_from_pvec!(obj, isCalibrated);
            # println("Found object")
            # show(pvec.pv[1])
            # show(obj)
        end
    end
    return nothing
end



"""
    $(SIGNATURES)

Sync all values from object's param vector into object.
"""
function sync_values!(x)
    set_values_from_pvec!(x, true);
    set_default_values!(x, false);
end


"""
    check_calibrated_params

Check that param vector values are consistent with object values
"""
function check_calibrated_params(x, pvec)
    d = make_dict(pvec, true);
    valid = true;
    for (pName, pValue) in d
        isValid = getproperty(x, pName) ≈ pValue;
        if ~isValid
            valid = false;
            @warn "Invalid value: $pName"
        end
    end
    return valid
end


"""
    check_fixed_params

Check that all fixed parameters have the correct values
"""
function check_fixed_params(x, pvec)
    # Make dict of default values for non-calibrated params
    d = make_dict(pvec, false);
    valid = true;
    for (pName, pValue) in d
        isValid = getproperty(x, pName) ≈ pValue;
        if ~isValid
            valid = false;
            @warn "Invalid value: $pName"
        end
    end
    return valid
end


"""
    $(SIGNATURES)

Copy values from vector into param vector and object.
Calibrated parameters.
Uses the first `nUsed` values in `vAll`.
Order in `vAll` must match order in `pvec`. E.g., because `vAll` is generated by `make_vector`.
"""
function sync_from_vector!(x, vAll :: Vector{ValueType})
    pvec = get_pvector(x);
    d11, nUsed1 = vector_to_dict(pvec, vAll, true);
    set_values_from_dict!(pvec, d11);
    set_values_from_pvec!(x, true);
    return nUsed1
end

"""
    $(SIGNATURES)

Copy values from a *vector* of `ParamVector` into a *vector* of `ModelObject`s.
The order of the objects must match the order of the `ParamVector`s.
The order of the values in `vAllInV` must match the order of `ParamVector`s.

OUT: 
    vAll: remaining values of vAllInV
"""
function sync_from_vector!(xV :: Vector, vAllInV :: Vector{ValueType})
    vAll = copy(vAllInV);
    for i1 = 1 : length(xV)
        # check that ParamVector matches model object
        # @assert check_match(pvecV[i1], xV[i1].objId);
        nUsed = sync_from_vector!(xV[i1], vAll);
        deleteat!(vAll, 1 : nUsed);
    end
    # Last object: everything should be used up
    # @assert isempty(vAll)  "Not all vector elements used"

    return vAll
end


# -----------------