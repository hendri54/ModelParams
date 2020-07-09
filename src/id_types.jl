## ----------  ObjectId

"""
    SingleId

Id for one object or object vector. 
Does not keep track of location in model.
Keeps track of `name` (Symbol identifier), `index`, and `description` (for display purposes).

`index` is used when there is a vector or matrix of objects of the same type
`index` is typically empty (scalar object) or scalar (vector objects)
"""
struct SingleId
    name :: Symbol
    index :: Array{Int}
    description :: String
end


"""
    ObjectId

Complete, unique ID of a `ModelObject`

Contains own id and a vector of parent ids, so one knows exactly where the object
is placed in the model tree.
"""
struct ObjectId
    # Store IDs as vector, not tuple (b/c empty tuples are tricky)
    # "Youngest" member is positioned last in vector
    ids :: Vector{SingleId}
end

# -------------