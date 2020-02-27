"""
	$(SIGNATURES)

Is `o` a `ModelObject`?
"""
is_model_object(o :: ModelObject) = true;
is_model_object(o) = false;


"""
	$(SIGNATURES)

Retrieve an objects ObjectId. Return `nothing` if not found.
"""
get_object_id(o :: ModelObject) = o.objId :: ObjectId
get_object_id(o) = nothing;


"""
	$(SIGNATURES)

Does object contain a `ParamVector`. Override for user defined types.
By default, ModelObjects are assumed to have `ParamVector`s.
"""
has_pvector(o :: ModelObject) = true;
has_pvector(o) = false;


"""
	$(SIGNATURES)

Find the ParamVector. Return empty if not found.
Override for user types.
"""
function get_pvector(o)
    # Try the default field
    if has_pvector(o)  &&  isdefined(o, :pvec)
        pvec = o.pvec;
    else
        pvec = ParamVector(o.objId);
    end
    return pvec :: ParamVector
end

#     if !found
#         for pn = propertynames(o)
#             obj = getproperty(o, pn);
#             if isa(obj, ParamVector)
#                 pvec = obj;
#                 found = true;
#                 break;
#             end
#         end
#     end
#     return pvec :: ParamVector
# end


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


"""
	$(SIGNATURES)

Show structure of a `ModelObject`.
"""
function show(io :: IO,  o :: ModelObject)
    show_object_structure(io, o);
end

function show_object_structure(io :: IO, o)
    objV = collect_model_objects(o);
    if !isempty(objV)
        for obj in objV
            println(io,  make_string(get_object_id(obj)) * " \t $(typeof(obj))");
        end
    end
    return nothing
end


"""
    $(SIGNATURES)

Collect all model objects inside an object. Only those that have a `pvector`.
Recursive. Also collects objects inside child objects and so on.
Returns empty `Vector` if no objects found.
"""
function collect_model_objects(o :: ModelObject)
    outV = Vector{Any}();
    if has_pvector(o)
        push!(outV, o);
    end

    # Objects directly contained in `o`
    childObjV = get_child_objects(o);
    if !Base.isempty(childObjV)
        for i1 = 1 : length(childObjV)
            nestedObjV = collect_model_objects(childObjV[i1]);
            append!(outV, nestedObjV);
        end
    end
    return outV :: Vector
end

collect_model_objects(o) = Vector{Any}();


"""
    $(SIGNATURES)

Find the child objects inside a model object.
Returns empty Vector if no objects found.
"""
function get_child_objects(o :: ModelObject)
    childV = Vector{Any}();
    for pn in propertynames(o)
        obj = getproperty(o, pn);
        if isa(obj, Vector)
            # This check is not quite right. But objects should all be the same type.
            if is_model_object(obj[1])
                append!(childV, obj);
            end
        else
            if is_model_object(obj)
                push!(childV, obj);
            end
        end
    end
    return childV :: Vector
end

get_child_objects(o) = Vector{Any}();


"""
	$(SIGNATURES)

Find child object with a given `ObjectId`.
Returns `nothing` if not found.
"""
function find_object(o :: ModelObject, id :: ObjectId)
    oOut = nothing;
    objV = collect_model_objects(o);
    if !isempty(objV)
        for obj in objV
            if isequal(get_object_id(obj), id)
                oOut = obj;
                break;
            end
        end
    end
    return oOut
end

find_object(o, id :: ObjectId) = nothing;


"""
	$(SIGNATURES)

Find all child objects that have a name given by a `Symbol`. Easier than having to specify an entire `ObjectId`.
"""
function find_object(o :: ModelObject, oName :: Symbol)
    outV = Vector{Any}();
    objV = collect_model_objects(o);
    if !isempty(objV)
        for obj in objV
            if own_name(obj) == oName
                push!(outV, obj);
            end
        end
    end
    return outV
end

find_object(o, oName :: Symbol) = Vector{Any}();


"""
	$(SIGNATURES)

Collect all `ParamVector`s in an object.
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


## -------------  Setting values


"""
	$(SIGNATURES)

Change value of a field in a `ModelObject` and its `ParamVector`.
"""
function change_value!(x :: ModelObject, oName :: Symbol, pName :: Symbol,  newValue)
    objV = find_object(x, oName);
    @assert length(objV) == 1  "Found $(length(objV)) matches for $oName / $pName"
    pvec = get_pvector(objV[1]);
    @assert length(pvec) > 0  "No ParamVector in $oName / $pName"
    oldValue = change_value!(pvec, pName, newValue);
    # Set value in object as well
    setfield!(objV[1], pName, newValue);
    return oldValue
end


"""
	$(SIGNATURES)

Retrieve the value of a field in a `ModelObject` or its children.
Object name `oName` must be unique.
"""
function get_value(x :: ModelObject, oName :: Symbol, pName :: Symbol)
    objV = find_object(x, oName);
    @assert length(objV) == 1  "Found $(length(objV)) matches for $oName / $pName"
    return getfield(objV[1], pName)
end


## Set fields in struct from param vector (using values, not defaults)
function set_values_from_pvec!(x :: ModelObject, isCalibrated :: Bool)
    pvec = get_pvector(x);
    d = make_dict(pvec, isCalibrated, true);
    set_values_from_dict!(x, d);
    return nothing
end


## Set default values from param vector
#Typically for non-calibrated parameters
function set_default_values!(x :: ModelObject, isCalibrated :: Bool)
    pvec = get_pvector(x);
    # Last arg: use default values
    d = make_dict(pvec, isCalibrated, false);
    set_values_from_dict!(x, d);
    return nothing
end


## Set fields in a struct from a Dict{Symbol, Any}.
# Does not change `ParamVector` inside `x` (if any)
function set_values_from_dict!(x :: ModelObject,  d :: Dict{Symbol, Any})
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
function set_values_from_pvectors!(x :: ModelObject, v :: Vector{ParamVector}, isCalibrated :: Bool)
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
function sync_values!(x :: ModelObject)
    set_values_from_pvec!(x, true);
    set_default_values!(x, false);
end


"""
    check_calibrated_params

Check that param vector values are consistent with object values
"""
function check_calibrated_params(x :: ModelObject, pvec)
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
function check_fixed_params(x :: ModelObject, pvec)
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
function sync_from_vector!(x :: ModelObject, vAll :: Vector{ValueType})
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