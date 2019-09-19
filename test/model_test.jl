## -------------  Test model
# More extensive testing in `SampleModel`

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

function init_obj1()
    objId = ObjectId(:obj1);
    px = Param(:x, "x obj1", "x1", 11.1, 9.9, 1.1, 99.9, true);
    valueY = [1.1, 2.2];
    py = Param(:y, "y obj1", "y1", valueY, valueY .+ 1.0,
        valueY .- 5.0, valueY .+ 5.0, true);
    valueZ = [3.3 4.4; 5.5 7.6];
    pz = Param(:z, "z obj1", "z1", valueZ, valueZ .+ 1.0,
        valueZ .- 5.0, valueZ .+ 5.0, false);
    pvector = ParamVector(objId, [px, py, pz])
    o1 = Obj1(objId, px.value, py.value, pz.value, pvector);
    ModelParams.set_values_from_pvec!(o1, pvector, true);
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

function init_obj2()
    objId = ObjectId(:obj2);
    pa = Param(:a, "a obj2", "a2", 12.1, 7.9, -1.1, 49.9, true);
    valueY = 9.4;
    py = Param(:y, "y obj2", "y2", valueY, valueY .+ 1.0,
        valueY .- 5.0, valueY .+ 5.0, true);
    valueB = 2.0 .+ [3.3 4.4; 5.5 7.6];
    pb = Param(:b, "b obj2", "b2", valueB, valueB .+ 1.0,
        valueB .- 5.0, valueB .+ 5.0, true);
    pvector = ParamVector(objId, [pa, py, pb]);
    o2 = Obj2(objId, pa.value, py.value, pb.value, pvector);
    ModelParams.set_values_from_pvec!(o2, pvector, true);
    return o2
end

mutable struct TestModel <: ModelObject
    objId :: ObjectId
    o1 :: Obj1
    # pvec1 :: ParamVector
    o2 :: Obj2
    # pvec2 :: ParamVector
    a :: Float64
    y :: Float64
end

function init_test_model()
    o1 = init_obj1();
    o2 = init_obj2();
    return TestModel(ObjectId(:testModel), o1, o2, 9.87, 87.73)
end



## -----------  Simulates the workflow for calibration
# More extensive testing in `SampleModel`

function model_test()
    @testset "Model" begin
        m = init_test_model()

        println("-----  Model parameters: calibrated")
        ModelParams.report_params(m, true);
        println("-----  Model parameters: fixed")
        ModelParams.report_params(m, false);
        nParam, nElem = ModelParams.n_calibrated_params(m, true);
        @test nParam > 1
        @test nElem > nParam
        nParam, nElem = ModelParams.n_calibrated_params(m, false);
        @test nParam >= 1
        @test nElem > nParam

        isCalibrated = true;

        # Sync calibrated model values with param vector
        ModelParams.set_values_from_pvec!(m.o1, m.o1.pvec, isCalibrated);
        # also sync the non-calibrated default values
        ModelParams.set_default_values!(m.o1, m.o1.pvec, false);
        @test ModelParams.check_calibrated_params(m.o1, m.o1.pvec);
        @test ModelParams.check_fixed_params(m.o1, m.o1.pvec);

        # The same in one step
        ModelParams.sync_values!(m.o2, m.o2.pvec);
        @test ModelParams.check_calibrated_params(m.o2, m.o2.pvec);
        @test ModelParams.check_fixed_params(m.o2, m.o2.pvec);

        # This step just for testing
        # These are the values that we expect to get back in the end
        d1 = make_dict(m.o1.pvec, isCalibrated);
        d2 = make_dict(m.o2.pvec, isCalibrated);


        # For each model object: make vector of param values
        v1, lb1, ub1 = make_vector(m.o1.pvec, isCalibrated);
        @test isa(v1, Vector{Float64})
        v2, lb2, ub2 = make_vector(m.o2.pvec, isCalibrated);
        @test isa(v2, Vector{Float64})

        # This is passed to optimizer as guess
        vAll = [v1; v2];
        @test isa(vAll, Vector{Float64})

        # Same in one step for all param vectors
        vAll2, lbAllV, ubAllV = ModelParams.make_vector([m.o1.pvec, m.o2.pvec], isCalibrated);
        @test vAll ≈ vAll2
        @test lbAllV ≈ [lb1; lb2]
        @test ubAllV ≈ [ub1; ub2]

        # Now we run the optimizer, which changes `vAll`



        # In the objective function: the guess is reassembled
        # into dicts which are then put into the objects

        # Using in a single convenience method
        vOut = ModelParams.sync_from_vector!([m.o1, m.o2], [m.o1.pvec, m.o2.pvec], vAll);
        @test isempty(vOut);
        @test ModelParams.check_calibrated_params(m.o1, m.o1.pvec);
        @test ModelParams.check_fixed_params(m.o1, m.o1.pvec);
        @test ModelParams.check_calibrated_params(m.o2, m.o2.pvec);
        @test ModelParams.check_fixed_params(m.o2, m.o2.pvec);

        # The same step-by-step. Only needed for testing
        d11, nUsed1 = vector_to_dict(m.o1.pvec, vAll, isCalibrated);
        @test d11[:x] == d1[:x]
        @test d11[:y] == d1[:y]
        # copy into param vector; then sync with model object
        ModelParams.set_values_from_dict!(m.o1.pvec, d11);
        ModelParams.set_values_from_pvec!(m.o1, m.o1.pvec, isCalibrated);
        @test m.o1.x ≈ d1[:x]
        @test m.o1.y ≈ d1[:y]

        # The same in a single convenience function, one object at a time
        # Just for testing
        nUsed11 = ModelParams.sync_from_vector!(m.o1, m.o1.pvec, vAll);
        @test nUsed11 == nUsed1
        @test m.o1.x ≈ d1[:x]
        @test m.o1.y ≈ d1[:y]
        deleteat!(vAll, 1 : nUsed1);

        d22, nUsed2 = ModelParams.vector_to_dict(m.o2.pvec, vAll, isCalibrated);
        @test d22[:a] == d2[:a]
        @test d22[:b] == d2[:b]
        ModelParams.set_values_from_dict!(m.o2.pvec, d22);
        ModelParams.set_values_from_pvec!(m.o2, m.o2.pvec, isCalibrated);
        @test m.o2.a ≈ d2[:a]
        @test m.o2.b ≈ d2[:b]
        # Last object: everything should be used up
        @test length(vAll) == nUsed2

        # Test changing parameters
        d22[:a] = 59.34;
        ModelParams.set_values_from_dict!(m.o2, d22);
        @test m.o2.a ≈ d22[:a]

        d22[:b] .+= 3.8;
        ModelParams.set_values_from_dict!(m.o2.pvec, d22);
        ModelParams.set_values_from_pvec!(m.o2, m.o2.pvec, isCalibrated);
        @test m.o2.b ≈ d22[:b]
    end
end


# -------------