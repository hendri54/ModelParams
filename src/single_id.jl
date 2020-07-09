export SingleId, has_index

## ----------  SingleId

# Object without index
SingleId(name :: Symbol) = SingleId(name, Array{Int,1}(), "");

SingleId(name :: Symbol, idx :: T1, descr = "") where T1 <: Integer =
    SingleId(name, [idx], descr);

SingleId(name :: Symbol, idxM :: Array{I1}) where I1 <: Integer =
    SingleId(name, idxM, "");

SingleId(name :: Symbol, descr :: String) = SingleId(name, Array{Int,1}(), descr);


# Make a string of the form "x[2, 1]"
function show_string(s :: SingleId)
    outStr = string(s.name);
    if !isempty(s.index)
        outStr = outStr * "$(s.index)";
    end
    return outStr
end

show(io :: IO,  s :: SingleId) = 
    print(io,  "SingleId:  $(show_string(s))");

description(s :: SingleId) = s.description;
name(s :: SingleId) = s.name;
index(s :: SingleId) = s.index;

function has_index(this :: SingleId)
    return !Base.isempty(this.index)
end

function isequal(id1 :: SingleId, id2 :: SingleId)
    return (id1.name == id2.name)  &&  (id1.index == id2.index)
end

isequal(id1V :: Vector{SingleId},  id2V :: Vector{SingleId}) = 
    all(isequal.(id1V, id2V));

#     outVal = length(id1V) == length(id2V);
#     if outVal
#         for i1 = 1 : length(id1V)
#             outVal = outVal && isequal(id1V[i1], id2V[i1]);
#         end
#     end
#     return outVal
# end


"""
	$(SIGNATURES)

Make a string from o `SingleId`. Such as "x[2, 1]".
"""
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
	$(SIGNATURES)

The inverse of [`make_string`](@ref).
"""
function make_single_id(s :: T1) where T1 <: AbstractString
    if occursin('[', s)
        # Pattern "id1[4, 3]"
        m = match(r"(.+)\[([0-9, ]+)+\]", s);
        idxV = parse.(Int, split(m[2], ","));
        sId = SingleId(Symbol(m[1]),  idxV);
    else
        sId = SingleId(Symbol(s));
    end
    return sId
end


# ----------------