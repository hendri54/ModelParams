using ModelObjectsLH, ModelParams, Test

mdl = ModelParams;

function find_test()
    @testset "Find" begin
        m = init_test_model()
        @test check_own_fixed_params(m, get_pvector(m))
        @test check_own_calibrated_params(m, get_pvector(m))

        m2 = init_test_model();
        @test ModelParams.params_equal(m, m2)
    end
end


function change_values_test()
    @testset "Change values by hand" begin
        m = init_test_model();
        for (oName, pName) ∈ ((:o2, :y), (:obj3, :y), (:o4, :beta))
            vOld = mdl.get_value(m, oName, pName);
            vNew = vOld .+ 0.5;
            ModelParams.change_value!(m, oName, pName, vNew);
            @test ModelParams.get_value(m, oName, pName) ≈ vNew;
            obj = find_only_object(m, oName);
            p = retrieve(obj, pName);
            @test pvalue(p) ≈ vNew;

            @test pvalue(obj, pName) ≈ vNew;
            set_pvalue!(obj, pName, vNew .+ 0.1);
            @test pvalue(obj, pName) ≈ vNew .+ 0.1;
            set_pvalue!(obj, pName, vNew);

            pvec = get_pvector(obj);
            @test pvec isa ParamVector;
            p = pvec[1];
            @test p isa Param;
            if default_value(p) isa Real
                lb = -10.0;
                ub = 20.0;
            else
                sz = size(default_value(p));
                lb = fill(-10.0, sz);
                ub = fill(20.0, sz);
            end
            set_bounds!(obj, p.name; lb, ub);
            @test p.lb == lb;
            @test p.ub == ub;
        end
    end
end


function compare_params_test()
    @testset "Compare params" begin
        m1 = init_test_model();
        m2 = init_test_model();
        pMiss1, pMiss2, pDiff = compare_params(m1, m2);
        @test isempty(pMiss1);
        @test isempty(pMiss2);
        @test isempty(pDiff);

        o2 = find_only_object(m1, :o2);
        allowedV = [get_object_id(o2)];
        @test check_params_match(m1, m2, allowedV);

        mdl.change_value!(get_pvector(o2), :a, 3.3);
        pMiss1, pMiss2, pDiff = compare_params(m1, m2);
        @test isempty(pMiss1);
        @test isempty(pMiss2);
        @test pDiff[get_object_id(o2)][:a] == [:value]
        @test check_params_match(m1, m2, allowedV);

        o3 = find_only_object(m1, :obj3);
        mdl.change_value!(get_pvector(o3), :x, 0.888);
        @test !check_params_match(m1, m2, allowedV);

        tbM = report_param_differences(m1, m2);
        @test tbM isa Matrix{String};
        @test size(tbM, 1) > 1;

        # Param differences with params that differ in size
        oldSize = size(o2.b);
        newValue = [1.1 2.2];
        @test oldSize != size(newValue);
        o2New = init_obj2(get_object_id(o2); valueB = newValue);
        m2.o2 = o2New;
        tbM = report_param_differences(m1, m2);
        @test size(tbM, 1) > 1;
    end
end


# function dict_test()
#     @testset "Dict/Vector" begin
#         m = init_test_model();
#         isCalibrated = true;

#         d1 = make_dict(m.o1.pvec, isCalibrated);
#         d2 = make_dict(m.o2.pvec, isCalibrated);

#         # Sync values for one object
#         ModelParams.sync_own_values!(m.o2);
#         @test ModelParams.check_calibrated_params(m.o2, m.o2.pvec);
#         @test ModelParams.check_fixed_params(m.o2, m.o2.pvec);

#         # The same step-by-step. Only needed for testing
#         vv = ModelParams.make_guess(m.o1.pvec, isCalibrated);
#         # update ++++++
#         # d11, nUsed1 = vector_to_dict(m.o1.pvec, vv, isCalibrated);
#         # @test d11[:x] ≈ d1[:x]
#         # @test d11[:y] ≈ d1[:y]

#         ModelParams.sync_own_from_vector!(m, vv);
#         # @test nUsed11 == nUsed1

#         # copy into param vector; then sync with model object
#         ModelParams.set_values_from_dict!(m.o1.pvec, d11);
#         ModelParams.set_own_values_from_pvec!(m.o1, isCalibrated);
#         @test m.o1.x ≈ d1[:x]
#         @test m.o1.y ≈ d1[:y]

#         # Sync calibrated model values with param vector
#         ModelParams.set_own_values_from_pvec!(m.o1, isCalibrated);
#         # also sync the non-calibrated default values
#         ModelParams.set_own_default_values!(m.o1, false);
#         @test ModelParams.check_calibrated_params(m.o1, m.o1.pvec);
#         @test ModelParams.check_fixed_params(m.o1, m.o1.pvec);
#     end
# end


function param_tables_test()
    @testset "Parameter table" begin
        m = init_test_model();
        d = param_tables(m, true);
        @test isa(d, Dict{ObjectId, ModelParams.ParamTable})

        pvecV = collect_pvectors(m);
        objIdV = [get_object_id(pvec)  for (_, pvec) ∈ pvecV];
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
    compare_params_test();
    change_values_test();
    param_tables_test();
    # sync_test();
end


# -----------------