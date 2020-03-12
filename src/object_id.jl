# function ParentId()
#     return ParentId(Vector{SingleId}())
# end

## ---------  Constructors

ObjectId() = ObjectId(Vector{SingleId}());

# Without a parent or index
function ObjectId(ownId :: SingleId)
    return ObjectId([ownId]);
end

# With parent; no index
function ObjectId(name :: Symbol, parentIds :: ObjectId = ObjectId())
    return ObjectId(vcat(parentIds.ids, SingleId(name)))
end

# With everything
function ObjectId(name :: Symbol, index :: Vector{T1},
    parentIds :: ObjectId = ObjectId()) where T1 <: Integer

    return ObjectId(vcat(parentIds.ids, SingleId(name, index)))
end

function ObjectId(name :: Symbol, idx :: T1,
    parentIds :: ObjectId = ObjectId()) where T1 <: Integer

    return ObjectId(vcat(parentIds.ids,  SingleId(name, [idx])))
end


## ------  Parent info

function has_parent(oId :: ObjectId)
    return length(oId.ids) > 1
end

function get_parent_id(oId :: ObjectId)
    if has_parent(oId)
        return ObjectId(oId.ids[1 : (end-1)])
    else
        return ObjectId()
    end
end

is_parent_of(pId :: ObjectId,  oId :: ObjectId) = isequal(pId, get_parent_id(oId))



# Make child ID for an object
function make_child_id(obj :: T1, name :: Symbol,
    index :: Vector{T2} = Vector{Int}()) where {T1 <: ModelObject, T2 <: Integer}

    return ObjectId(name, index, obj.objId)
end

# Make child ID from parent's ID
function make_child_id(parentId :: ObjectId, name :: Symbol,
    index :: Vector{T2} = Vector{Int}()) where {T2 <: Integer}

    return ObjectId(name, index, parentId)
end


"""
	$(SIGNATURES)

Checks whether two `ObjectId`s are the same.
"""
function Base.isequal(id1 :: ObjectId,  id2 :: ObjectId)
    outVal = (length(id1.ids) == length(id2.ids))  &&  all(isequal.(id1.ids, id2.ids))
    return outVal
end


own_index(oId :: ObjectId) = oId.ids[end].index
# Return own SingleId
own_id(oId :: ObjectId) = oId.ids[end];


"""
	$(SIGNATURES)

Return object's own name as `Symbol`.
"""
function own_name(oId :: ObjectId)
    return name(own_id(oId))
end

function own_name(o :: ModelObject)
    return own_name(o.objId)
end


"""
	$(SIGNATURES)

Make string from ObjectId. Such as "p > q > r[4, 2]".
"""
function make_string(id :: ObjectId)
    outStr = "";
    for i1 = 1 : length(id.ids)
        if i1 > 1
            outStr = outStr  * ObjIdSeparator;
        end
        outStr = outStr * make_string(id.ids[i1]);
    end
    return outStr
end


"""
	$(SIGNATURES)

The inverse of `make_string`.
"""
function make_object_id(s :: T1) where T1 <: AbstractString
    if occursin(ObjIdSeparator, s)
        strV = split(s, ObjIdSeparator);
        singleIdV = similar(strV, SingleId);
        for (j, str) in enumerate(strV)
            singleIdV[j] = make_single_id(str);
        end
        return ObjectId(singleIdV)
    else
        return ObjectId(Symbol(s));
    end
end


"""
	$(SIGNATURES)

Show an object id.
"""
function show(io :: IO,  id :: ObjectId)
    println(io,  "ObjectId: " * make_string(id));
end


# ----------
