# Set up model for testing
using ModelObjectsLH, ModelParams

import ModelParams.has_pvector

mdl = ModelParams;

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
    # Important to have vector of length 1 as test case
    valueY = fill(1.1, 1);
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

mutable struct Obj3Switches <: ModelSwitches
    pvec :: ParamVector
end

function init_obj3_switches(objId :: ObjectId)
    # objId = ObjectId(:obj3);
    px = Param(:x, "x", "x", 0.5, 0.6, 0.0, 1.0, true);
    yV = [1.0, 2.0];
    py = Param(:y, "y", "y", yV, yV .+ 1.0, [0.0, 0.0], [9.0, 9.0], false);
    v = [1.0 2.0 3.0; 1.1 2.1 3.1];
    isCalM = [true false true; false true false];
    pca = CalArray(:ca, "CalArray", "CalArray", v, v .+ 0.1, v .- 2.0, v .+ 2.0,
        isCalM);
    pvec = ParamVector(objId, [px, py, pca]);
    return Obj3Switches(pvec)
end

ModelObjectsLH.get_object_id(switches :: Obj3Switches) = get_object_id(switches.pvec);

mutable struct Obj3 <: ModelObject
    objId :: ObjectId
    switches :: Obj3Switches
    x :: Float64
    y :: Vector{Float64}
    ca :: Matrix{Float64}
end

ModelParams.get_pvector(o :: Obj3) = o.switches.pvec;

function init_obj3(objId :: ObjectId)
    switches = init_obj3_switches(objId);
    ca = retrieve(switches.pvec, :ca);
    return Obj3(get_object_id(switches), switches, 0.5, [1.0, 2.0], default_value(ca));
end

mutable struct Obj2 <: ModelObject
    objId :: ObjectId
    a :: Float64
    y :: Float64
    b :: Array{Float64,2}
    bvec :: Vector{Float64}
    o3 :: Obj3
    pvec :: ParamVector
end

# function Obj2(a, y, b)
#     return Obj2(a, y, b, ParamVector(ObjectId(:pv1)))
# end

function init_obj2(objId; valueB = 2.0 .+ [3.3 4.4; 5.5 7.6])
    # objId = ObjectId(:obj2);
    pa = Param(:a, "a obj2", "a2", 12.1, 7.9, -1.1, 49.9, true);
    valueY = 9.4;
    py = Param(:y, "y obj2", "y2", valueY, valueY .+ 1.0,
        valueY .- 5.0, valueY .+ 5.0, true);
    pb = Param(:b, "b obj2", "b2", valueB, valueB .+ 1.0,
        valueB .- 5.0, valueB .+ 5.0, true);
    pBvec = mdl.make_test_bvector(:bvec; isCalibrated = true, increasing = :increasing);
    pvector = ParamVector(objId, [pa, py, pb, pBvec]);
    obj3 = init_obj3(make_child_id(objId, :obj3));
    o2 = Obj2(objId, pa.value, py.value, pb.value, pvalue(pBvec), obj3, pvector);
    ModelParams.set_own_values_from_pvec!(o2, true);
    return o2
end


## -----------  Obj4 
# Object that directly contains `Params` and has not directly stored values.

mutable struct Obj4 <: ModelObject
    objId :: ObjectId
    alpha :: Param{Float64}
    beta  :: Param{Vector{Float64}}
    gamma :: Param{Float64}
end

ModelParams.has_pvector(::Obj4) = true;
ModelParams.get_pvector(o :: Obj4) = 
    ParamVector(o.objId, [o.alpha, o.beta, o.gamma]);
ModelParams.pvalue(o :: Obj4, pName :: Symbol) = 
    ModelParams.pvalue(getfield(o, pName));
ModelParams.param_loc(::Obj4) = ModelParams.ParamsInObject();

function init_obj4(objId)
    Obj4(objId, 
        Param(:alpha, "alpha", "alpha", 1.0, 2.0, 0.0, 5.0, true),
        Param(:beta, "beta", "beta", 
            [1.0, 1.1], [2.0, 2.1], zeros(2), fill(5.0, 2), true),
        Param(:gamma, "gamma", "gamma", 1.5, 2.5, 0.0, 5.0, false)
        );
end


mutable struct TestModel <: ModelObject
    objId :: ObjectId
    o1 :: Obj1
    o2 :: Obj2
    o4 :: Obj4
    a :: Float64
    y :: Float64
end

has_pvector(o :: TestModel) = false;

function init_test_model()
    objName = ObjectId(:testModel, "Test model");
    o1 = init_obj1(ModelParams.make_child_id(objName, :o1, "Child object 1"));
    o2 = init_obj2(ModelParams.make_child_id(objName, :o2, "Child object 2"));
    o4 = init_obj4(ModelParams.make_child_id(objName, :o4, "Child object 4"));
    m = TestModel(objName, o1, o2, o4, 9.87, 87.73);
    sync_values!(m);
    return m
end

# ------------------