using ModelParams, Test

## -----------  Simulates the workflow for calibration
# More extensive testing in `SampleModel`

function report_test()
    @testset "Reporting" begin
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
    end
end


function model_test()
    @testset "Model" begin
        m = init_test_model()
        isCalibrated = true;

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
        vv = ModelParams.make_guess(m);
        @test ModelParams.sync_from_vector!([m.o1, m.o2], vv);
        @test ModelParams.check_calibrated_params(m.o1, m.o1.pvec);
        @test ModelParams.check_fixed_params(m.o1, m.o1.pvec);
        @test ModelParams.check_calibrated_params(m.o2, m.o2.pvec);
        @test ModelParams.check_fixed_params(m.o2, m.o2.pvec);


        # The same in a single convenience function, one object at a time
        # Just for testing
        nUsed11 = ModelParams.sync_own_from_vector!(m.o1, vv);
        @test m.o1.x ≈ d1[:x]
        @test m.o1.y ≈ d1[:y]

        # vv = ModelParams.make_vector(m.o2.pvec, isCalibrated);
        d22, nUsed2 = ModelParams.vector_to_dict(m.o2.pvec, vv, isCalibrated;
            startIdx = nUsed11 + 1);
        @test d22[:a] == d2[:a]
        @test d22[:b] == d2[:b]
        ModelParams.set_values_from_dict!(m.o2.pvec, d22);
        ModelParams.set_own_values_from_pvec!(m.o2, isCalibrated);
        @test m.o2.a ≈ d2[:a]
        @test m.o2.b ≈ d2[:b]
        # Last object: everything should be used up
        @test length(vAll) == nUsed2

        # Test changing parameters
        d22[:a] = 59.34;
        ModelParams.set_own_values_from_dict!(m.o2, d22);
        @test m.o2.a ≈ d22[:a]

        d22[:b] .+= 3.8;
        ModelParams.set_values_from_dict!(m.o2.pvec, d22);
        ModelParams.set_own_values_from_pvec!(m.o2, isCalibrated);
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
        @test ModelParams.params_equal(m, m2)
        guess2V = ModelParams.perturb_guess(m2, guessV, 0.1; dIdx = 4);
        guess2 = perturb_guess(m2, vv, 0.1; dIdx = 4);
        @test isapprox(values(guess2), guess2V, atol = 1e-6)

        m2 = init_test_model();
        @test ModelParams.params_equal(m, m2)
        # guess2V = ModelParams.perturb_guess(m2, guessV, 0.1);
        guess2 = perturb_guess(m2, vv, 0.1);
        # @test isapprox(values(guess2), guess2V, atol = 1e-6)
        
        # Two interfaces for setting parameters
        # ModelParams.set_params_from_guess!(m2, guess2V);
        # guess3 = make_guess(m2);
        ModelParams.set_params_from_guess!(m2, guess2);
        guess4 = make_guess(m2);
        @test isapprox(guess2, guess4)
        @test !ModelParams.params_equal(m, m2)

        # Restore values from pvectors
        ModelParams.set_values_from_pvectors!(m2, pvecV, true);
        # Check that we get the same guessV
        vv3 = make_guess(m);
        @test isapprox(vv, vv3)

        m3 = init_test_model();
        perturb_params(m3, 0.1);
        @test !params_equal(m, m3)
        guess5 = make_guess(m3)
        @test !isapprox(vv, guess5; atol = 1e-5)
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
        guess3V = perturb_guess(m, guessV, 0.1);
        ModelParams.set_params_from_guess!(m, guess3V);
        @test isapprox(make_guess(m), guess3V)

        # Restore the original parameters from Dict
        ModelParams.set_values_from_dicts!(m, d; isCalibrated = true);
        guess4V = make_guess(m)
        @test isapprox(guess4V, guessV)
    end
end


@testset "Model" begin
    report_test();
    model_test();
    set_values_test();
    dict_test()
end


# -------------