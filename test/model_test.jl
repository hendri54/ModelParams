using ModelParams, Test

## -------------  Test `ModelObject`
# More extensive testing in `SampleModel`

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
    ModelParams.set_values_from_pvec!(o1, true);
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
    ModelParams.set_values_from_pvec!(o2, true);
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

has_pvector(o :: TestModel) = false;

function init_test_model()
    objName = ObjectId(:testModel);
    o1 = init_obj1(ModelParams.make_child_id(objName, :o1));
    o2 = init_obj2(ModelParams.make_child_id(objName, :o2));
    return TestModel(objName, o1, o2, 9.87, 87.73)
end


## --------------  Tests

function find_test()
    @testset "Find" begin
        m = init_test_model()

        childId1 = ModelParams.make_child_id(m, :child)

        # Find objects by name
        @test isnothing(ModelParams.find_object(m, childId1))
        @test isempty(ModelParams.find_object(m, :child))

        childId2 = ModelParams.make_child_id(m, :o1);
        child2 = ModelParams.find_object(m, childId2);
        @test isa(child2, ModelObject)

        child2 = ModelParams.find_object(m, :o1);
        @test length(child2) == 1
        @test isequal(child2[1].objId, childId2)

        # Find the object itself. Does not return anything b/c object has no `pvector`
        m2 = ModelParams.find_object(m, m.objId);
        @test isnothing(m2)
    end
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
        ModelParams.set_values_from_pvec!(m.o1, isCalibrated);
        # also sync the non-calibrated default values
        ModelParams.set_default_values!(m.o1, false);
        @test ModelParams.check_calibrated_params(m.o1, m.o1.pvec);
        @test ModelParams.check_fixed_params(m.o1, m.o1.pvec);

        # The same in one step
        ModelParams.sync_values!(m.o2);
        @test ModelParams.check_calibrated_params(m.o2, m.o2.pvec);
        @test ModelParams.check_fixed_params(m.o2, m.o2.pvec);

        # This step just for testing
        # These are the values that we expect to get back in the end
        d1 = make_dict(m.o1.pvec, isCalibrated);
        d2 = make_dict(m.o2.pvec, isCalibrated);


        # For each model object: make vector of param values
        vv1 = make_vector(m.o1.pvec, isCalibrated);
        @test isa(ModelParams.values(vv1), Vector{Float64})
        vv2 = make_vector(m.o2.pvec, isCalibrated);
        @test isa(ModelParams.values(vv2), Vector{Float64})

        # This is passed to optimizer as guess
        vAll = [ModelParams.values(vv1); ModelParams.values(vv2)];
        @test isa(vAll, Vector{Float64})

        # Same in one step for all param vectors
        vv = ModelParams.make_vector([m.o1.pvec, m.o2.pvec], isCalibrated);
        @test vAll ≈ ModelParams.values(vv)
        @test ModelParams.lb(vv) ≈ [ModelParams.lb(vv1); ModelParams.lb(vv2)]
        @test ModelParams.ub(vv) ≈ [ModelParams.ub(vv1); ModelParams.ub(vv2)]

        # Now we run the optimizer, which changes `vAll`



        # In the objective function: the guess is reassembled
        # into dicts which are then put into the objects

        # Using in a single convenience method
        vOut = ModelParams.sync_from_vector!([m.o1, m.o2], vAll);
        @test isempty(vOut);
        @test ModelParams.check_calibrated_params(m.o1, m.o1.pvec);
        @test ModelParams.check_fixed_params(m.o1, m.o1.pvec);
        @test ModelParams.check_calibrated_params(m.o2, m.o2.pvec);
        @test ModelParams.check_fixed_params(m.o2, m.o2.pvec);

        # The same step-by-step. Only needed for testing
        d11, nUsed1 = vector_to_dict(m.o1.pvec, vAll, isCalibrated);
        @test d11[:x] ≈ d1[:x]
        @test d11[:y] ≈ d1[:y]
        # copy into param vector; then sync with model object
        ModelParams.set_values_from_dict!(m.o1.pvec, d11);
        ModelParams.set_values_from_pvec!(m.o1, isCalibrated);
        @test m.o1.x ≈ d1[:x]
        @test m.o1.y ≈ d1[:y]

        # The same in a single convenience function, one object at a time
        # Just for testing
        nUsed11 = ModelParams.sync_from_vector!(m.o1, vAll);
        @test nUsed11 == nUsed1
        @test m.o1.x ≈ d1[:x]
        @test m.o1.y ≈ d1[:y]
        deleteat!(vAll, 1 : nUsed1);

        d22, nUsed2 = ModelParams.vector_to_dict(m.o2.pvec, vAll, isCalibrated);
        @test d22[:a] == d2[:a]
        @test d22[:b] == d2[:b]
        ModelParams.set_values_from_dict!(m.o2.pvec, d22);
        ModelParams.set_values_from_pvec!(m.o2, isCalibrated);
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
        ModelParams.set_values_from_pvec!(m.o2, isCalibrated);
        @test m.o2.b ≈ d22[:b]
    end
end


function set_values_test()
    @testset "set values" begin
        m = init_test_model();
        pvecV = collect_pvectors(m);
        vv = make_guess(m);
        guessV = ModelParams.values(vv);

        # Change values arbitrarily. Need a copy of the model object; otherwise `pvec` is changed
        m2 = init_test_model();
        guess2V = ModelParams.perturb_guess(m2, guessV, 1 : length(guessV), 0.1);
        guess2 = perturb_guess(m2, vv, 1 : length(guessV), 0.1);
        @test isapprox(values(guess2), guess2V, atol = 1e-6)
        
        # Two interfaces for setting parameters
        ModelParams.set_params_from_guess!(m2, guess2V);
        guess3 = make_guess(m2);
        ModelParams.set_params_from_guess!(m2, guess2);
        guess4 = make_guess(m2);
        @test isapprox(guess3, guess4)

        # Restore values from pvectors
        ModelParams.set_values_from_pvectors!(m2, pvecV, true);
        # Check that we get the same guessV
        vv3 = make_guess(m);
        @test isapprox(vv, vv3)
    end
end


function change_values_test()
    @testset "Change values by hand" begin
        m = init_test_model();
        yNew = m.o2.y .+ 0.5;
        ModelParams.change_value!(m, :o2, :y, yNew);
        @test ModelParams.get_value(m, :o2, :y) .≈ yNew
        @test m.o2.y .≈ yNew
    end
end


## Model object -> Dict and back
function dict_test()
    @testset "Dict" begin
        m = init_test_model();
        guessV = make_guess(m);
        pvecV = collect_pvectors(m);
        d = make_dict(pvecV; isCalibrated = true);

        # Change parameters
        guess3V = perturb_guess(m, guessV, 1 : length(guessV), 0.1);
        ModelParams.set_params_from_guess!(m, guess3V);
        @test isapprox(make_guess(m), guess3V)

        # Restore the original parameters from Dict
        ModelParams.set_values_from_dicts!(m, d; isCalibrated = true);
        guess4V = make_guess(m)
        @test isapprox(guess4V, guessV)
    end
end


@testset "Model" begin
    find_test();
    model_test();
    set_values_test();
    change_values_test();
    dict_test()
end


# -------------