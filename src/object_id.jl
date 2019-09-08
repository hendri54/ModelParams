export SingleId, ObjectId, has_index, make_child_id


"""
    SingleId

Id for one object or object vector. 
Does not keep track of location in model.
"""
struct SingleId
    name :: Symbol
    # `index` is used when there is a vector of objects of the same type
    index :: Array{Int}
end

# Object without index
function SingleId(name :: Symbol)
    return SingleId(name, Array{Int,1}())
end

function SingleId(name :: Symbol, idx :: T1) where T1 <: Integer
    return SingleId(name, [idx])
end

function has_index(this :: SingleId)
    return !Base.isempty(this.index)
end

function isequal(id1 :: SingleId, id2 :: SingleId)
    return (id1.name == id2.name)  &&  (id1.index == id2.index)
end

function isequal(id1V :: Vector{SingleId},  id2V :: Vector{SingleId})
    outVal = length(id1V) == length(id2V);
    if outVal
        for i1 = 1 : length(id1V)
            outVal = outVal && isequal(id1V[i1], id2V[i1]);
        end
    end
    return outVal
end

function make_string(id :: SingleId)
    if !has_index(id)
        outStr = "$(id.name)"
    elseif length(id.index) == 1
        outStr = "$(id.name)$(id.index)"
    else
        outStr = "$(id.name)$(id.index)"
    end
    return outStr
end


"""
    ObjectId

Complete, unique ID of a `ModelObject`

Contains own id and a vector of parent ids, so one knows exactly where the object
is placed in the model tree
"""
struct ObjectId
    # Store IDs as vector, not tuple (b/c empty tuples are tricky)
    # "Youngest" member is positioned last in vector
    ids :: Vector{SingleId}
end

"""
    ParentId

This is actually identical to `ObjectId` but avoid recursive definitions
"""
struct ParentId
    ids :: Vector{SingleId}
end

function ParentId()
    return ParentId(Vector{SingleId}())
end

## ---------  Constructors

# Without a parent or index
function ObjectId(ownId :: SingleId)
    return ObjectId([ownId]);
end

# With parent; no index
function ObjectId(name :: Symbol, parentIds :: Union{ObjectId, ParentId} = ParentId())
    return ObjectId(vcat(parentIds.ids, SingleId(name)))
end

# With everything
function ObjectId(name :: Symbol, index :: Vector{T1},
    parentIds :: Union{ObjectId, ParentId} = ParentId()) where T1 <: Integer

    return ObjectId(vcat(parentIds.ids, SingleId(name, index)))
end

function ObjectId(name :: Symbol, idx :: T1,
    parentIds :: Union{ObjectId, ParentId} = ParentId()) where T1 <: Integer

    return ObjectId(vcat(parentIds.ids,  SingleId(name, [idx])))
end


## ------  Parent info

function has_parent(oId :: ObjectId)
    return length(oId.ids) > 1
end

function get_parent_id(oId :: ObjectId)
    if has_parent(oId)
        return ParentId(oId.ids[1 : (end-1)])
    else
        return ParentId()
    end
end

function is_parent_of(pId :: Union{ObjectId, ParentId},  oId :: ObjectId)
    if !has_parent(oId)
        return false
    else
        return all(isequal.(pId.ids,  oId.ids[1 : (end-1)]))
    end
end

function convert_to_parent_id(oId :: ObjectId)
    return ParentId(oId.ids)
end


# Make child ID for an object
function make_child_id(obj :: T1, name :: Symbol,
    index :: Vector{T2} = Vector{Int}()) where {T1 <: ModelObject, T2 <: Integer}

    return ObjectId(name, index, convert_to_parent_id(obj.objId))
end

# Make child ID from parent's ID
function make_child_id(parentId :: ObjectId, name :: Symbol,
    index :: Vector{T2} = Vector{Int}()) where {T2 <: Integer}

    return ObjectId(name, index, convert_to_parent_id(parentId))
end

function isequal(id1 :: Union{ObjectId, ParentId},  id2 :: Union{ObjectId, ParentId})
    outVal = all(isequal.(id1.ids, id2.ids))
    # outVal = isequal(id1.ownId, id2.ownId);
    # if length(id1.parentIds) != length(id2.parentIds)
    #     outVal = false;
    # else
    #     for i1 = 1 : length(id1.parentIds)
    #         outVal = outVal && isequal(id1.parentIds[i1], id2.parentIds[i1]);
    #     end
    # end
    return outVal
end


function own_index(oId :: ObjectId)
    return oId.ids[end].index
end


function make_string(id :: ObjectId)
    outStr = "";
    for i1 = 1 : length(id.ids)
        if i1 > 1
            outStr = outStr  * " > ";
        end
        outStr = outStr * make_string(id.ids[i1]);
    end
    return outStr
end

# ----------
