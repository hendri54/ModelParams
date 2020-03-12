# Set up model for testing
using ModelParams

import ModelParams.has_pvector

mutable struct Obj1 <: ModelObject
    objId :: ObjectId
    x :: Float64
    y :: Vector{Float64}
    z :: Array{Float64,2}
    pvec :: ParamVector
end

# function Obj1(x, y, z)
#     return Obj1(x, y, z, ParamVector(ObjectId(:pv1)))
# end

function init_obj1(objId)
    # objId = ObjectId(:obj1);
    px = Param(:x, "x obj1", "x1", 11.1, 9.9, 1.1, 99.9, true);
    valueY = [1.1, 2.2];
    py = Param(:y, "y obj1", "y1", valueY, valueY .+ 1.0,
        valueY .- 5.0, valueY .+ 5.0, true);
    valueZ = [3.3 4.4; 5.5 7.6];
    pz = Param(:z, "z obj1", "z1", valueZ, valueZ .+ 1.0,
        valueZ .- 5.0, valueZ .+ 5.0, false);
    pvector = ParamVector(objId, [px, py, pz])
    o1 = Obj1(objId, px.value, py.value, pz.value, pvector);
    ModelParams.set_own_values_from_pvec!(o1, true);
    return o1
end

mutable struct Obj2 <: ModelObject
    objId :: ObjectId
    a :: Float64
    y :: Float64
    b :: Array{Float64,2}
    pvec :: ParamVector
end

# function Obj2(a, y, b)
#     return Obj2(a, y, b, ParamVector(ObjectId(:pv1)))
# end

function init_obj2(objId)
    # objId = ObjectId(:obj2);
    pa = Param(:a, "a obj2", "a2", 12.1, 7.9, -1.1, 49.9, true);
    valueY = 9.4;
    py = Param(:y, "y obj2", "y2", valueY, valueY .+ 1.0,
        valueY .- 5.0, valueY .+ 5.0, true);
    valueB = 2.0 .+ [3.3 4.4; 5.5 7.6];
    pb = Param(:b, "b obj2", "b2", valueB, valueB .+ 1.0,
        valueB .- 5.0, valueB .+ 5.0, true);
    pvector = ParamVector(objId, [pa, py, pb]);
    o2 = Obj2(objId, pa.value, py.value, pb.value, pvector);
    ModelParams.set_own_values_from_pvec!(o2, true);
    return o2
end

mutable struct TestModel <: ModelObject
    objId :: ObjectId
    o1 :: Obj1
    o2 :: Obj2
    a :: Float64
    y :: Float64
end

has_pvector(o :: TestModel) = false;

function init_test_model()
    objName = ObjectId(:testModel);
    o1 = init_obj1(ModelParams.make_child_id(objName, :o1));
    o2 = init_obj2(ModelParams.make_child_id(objName, :o2));
    return TestModel(objName, o1, o2, 9.87, 87.73)
end

# ------------------