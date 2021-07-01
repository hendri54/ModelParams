using ModelObjectsLH, ModelParams, Random, Test

mdl = ModelParams;

function param_info_test()
    @testset "ParamInfo" begin
        pName = :p1;
        startIdx = 10;
        valueV = [1.0 2.0 3.0; 4.1 5.2 6.3];
        lbV = fill(0.5, size(valueV));
        ubV = fill(9.3, size(valueV));
        pInfo = ParamInfo(pName, startIdx, lbV, ubV);
        pInfo2 = ParamInfo(pName, startIdx, lbV, ubV);

        @test mdl.n_values(pInfo) == length(lbV);
        @test mdl.indices(pInfo)[1] == startIdx;
        @test length(mdl.indices(pInfo)) == mdl.n_values(pInfo);
        @test isapprox(pInfo, pInfo2);
        rv = mdl.random_values(pInfo, MersenneTwister(121));
        @test size(rv) == size(lbV);

        pInfo = ParamInfo(:p1, 2, 0.1, 9.3);
        rv = mdl.random_values(pInfo, MersenneTwister(121));
        @test rv isa Float64;
        # set_value!(pInfo, 3.3);
        # @test pInfo.valueV == 3.3;
        # set_value!(pInfo, [3.5]);
        # @test pInfo.valueV == 3.5;

        # pInfo = ParamInfo(:p1, 10, [2.1, 2.2], [0.0, 0.0], [5.0, 3.8]);
        # set_value!(pInfo, [3.0 2.9]);
        # @test pInfo.valueV == [3.0, 2.9];
    end
end

function value_vector_test()
    @testset "ValueVector" begin
        n = 5;
        vv = mdl.make_test_value_vector(n);
        nValues = mdl.n_values(vv);
        # valueV = collect(LinRange(0.5, 0.6, nValues));
        # mdl.set_values!(vv, valueV);
        # @test valueV == mdl.get_values(vv);
        rValueV = mdl.random_guess(vv, MersenneTwister(123));
        @test size(rValueV) == (nValues, );
    end
end

# function guess_test(isCalibrated)
#     @testset "Guess" begin
#         n = 4;
#         pvecV = mdl.make_test_pvector_collection(n);
#         g = make_guess(pvecV, isCalibrated);
#         valueV = get_values(g);
#         set_values!(g, valueV);
#         value2V = get_values(g);
#         @test isapprox(valueV, value2V);
#     end
# end

@testset "Guess" begin
    param_info_test();
    value_vector_test();
    # for isCalibrated in (true, false)
    #     guess_test(isCalibrated);
    # end
end

# ----------------