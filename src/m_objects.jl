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

Retrieve the value of a field in a `ModelObject` or its children.
Object name `oName` must be unique.
"""
function get_value(x :: ModelObject, oName :: Symbol, pName :: Symbol)
    objV = find_object(x, oName);
    @assert length(objV) == 1  "Found $(length(objV)) matches for $oName / $pName"
    return getfield(objV[1], pName)
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



# -----------------