function find_test()
    @testset "Find" begin
        m = init_test_model()
        @test check_fixed_params(m, get_pvector(m))
        @test check_calibrated_params(m, get_pvector(m))

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

        # Get value of a parameter
        b = ModelParams.get_value(m, :o2, :b);
        @test isequal(m.o2.b, b)

        m2 = init_test_model();
        @test ModelParams.params_equal(m, m2)
    end
end


function collect_test()
    @testset "Collect" begin
        m = init_test_model();
        v = collect_model_objects(m);
        @test length(v) == 2
        for o in v
            @test has_pvector(o)
        end
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


function dict_test()
    @testset "Dict/Vector" begin
        m = init_test_model();
        isCalibrated = true;

        d1 = make_dict(m.o1.pvec, isCalibrated);
        d2 = make_dict(m.o2.pvec, isCalibrated);

        # Sync values for one object
        ModelParams.sync_own_values!(m.o2);
        @test ModelParams.check_calibrated_params(m.o2, m.o2.pvec);
        @test ModelParams.check_fixed_params(m.o2, m.o2.pvec);

        # The same step-by-step. Only needed for testing
        vv = ModelParams.make_vector(m.o1.pvec, isCalibrated);
        d11, nUsed1 = vector_to_dict(m.o1.pvec, vv, isCalibrated);
        @test d11[:x] ≈ d1[:x]
        @test d11[:y] ≈ d1[:y]

        nUsed11 = ModelParams.sync_own_from_vector!(m, vv);
        @test nUsed11 == nUsed1

        # copy into param vector; then sync with model object
        ModelParams.set_values_from_dict!(m.o1.pvec, d11);
        ModelParams.set_own_values_from_pvec!(m.o1, isCalibrated);
        @test m.o1.x ≈ d1[:x]
        @test m.o1.y ≈ d1[:y]

        # Sync calibrated model values with param vector
        ModelParams.set_own_values_from_pvec!(m.o1, isCalibrated);
        # also sync the non-calibrated default values
        ModelParams.set_own_default_values!(m.o1, false);
        @test ModelParams.check_calibrated_params(m.o1, m.o1.pvec);
        @test ModelParams.check_fixed_params(m.o1, m.o1.pvec);
    end
end


function param_table_test()
    @testset "Parameter table" begin
        m = init_test_model();
        d = param_tables(m, true);
        @test isa(d, Dict{ObjectId, Matrix{String}})

        pvecV = collect_pvectors(m);
        objIdV = [get_object_id(pvec)  for pvec ∈ pvecV];
        descrV = ["Description j"  for j = 1 : length(pvecV)];
        lineV = latex_param_table(m, true, objIdV, descrV);
        @test isa(lineV, Vector{String})
        @test startswith(lineV[1], "\\multicolumn")
	end
end

# function sync_test()
#     @testset "Sync" begin
#         m = init_test_model();

# 	end
# end

@testset "Model Objects" begin
    find_test();
    collect_test();
    change_values_test();
    param_table_test();
    # sync_test();
end


# -----------------