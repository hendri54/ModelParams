using ModelParams, Test

mdl = ModelParams;

## -----------  Simulates the workflow for calibration
# More extensive testing in `SampleModel`

function report_test()
    @testset "Reporting" begin
        m = init_test_model()

        println("-----  Model parameters: calibrated");
        ModelParams.report_params(m, true);
        println("-----  Model parameters: fixed");
        ModelParams.report_params(m, false);
        nParam, nElem = ModelParams.n_calibrated_params(m; isCalibrated = true);
        @test nParam > 1
        @test nElem > nParam
        nParam, nElem = ModelParams.n_calibrated_params(m; isCalibrated = false);
        @test nParam >= 1
        @test nElem > nParam
    end
end


# Roughly simulates the flow of a model being calibrated using a solver that expectes a simple vector for the guesses.
function model_test()
    @testset "Model" begin
        # After construction: run `sync_values!` to ensure that all parameters are consistent with the `ParamVector`s.
        m = init_test_model();
        isCalibrated = true;

        g = mdl.make_guess(m);
        @test validate_guess(m, g);

        objV = [m.o1, m.o2, m.o2.o3];
        # These are the values that we expect to get back in the end
        dictV = [make_dict(get_pvector(obj); isCalibrated, valueType = :value)  for obj in objV];

        @test check_calibrated_params(m);
        @test check_fixed_params(m);

        # For each model object: make vector of param values
        # vv1 = make_guess(m.o1.pvec, isCalibrated);
        # @test isa(mdl.get_values(vv1), Vector{Float64})
        # vv2 = make_guess(m.o2.pvec, isCalibrated);
        # @test isa(mdl.get_values(vv2), Vector{Float64})

        # This is passed to optimizer as guess
        # vAll = [mdl.values(vv1); mdl.values(vv2)];
        # @test isa(vAll, Vector{Float64})

        # Same in one step for all param vectors
        # pvv = PVectorCollection();
        # push!(pvv, m.o1.pvec);
        # push!(pvv, m.o2.pvec);
        # vv = mdl.make_guess(pvv, isCalibrated);
        # @test vAll ≈ mdl.values(vv)
        # @test mdl.lb(vv) ≈ [mdl.lb(vv1); mdl.lb(vv2)]
        # @test mdl.ub(vv) ≈ [mdl.ub(vv1); mdl.ub(vv2)]

        # Now we run the optimizer, which changes `vAll`



        # In the objective function: the guess is reassembled
        # into dicts which are then put into the objects

        # Using in a single convenience method
        vVec = get_values(m, g);
        @test isa(vVec, Vector{Float64});
        @test validate_all_params(m; silent = false);

        for obj in objV
            @test mdl.check_own_calibrated_params(obj, get_pvector(obj));
            @test mdl.check_own_fixed_params(obj, get_pvector(obj));
            mdl.set_own_params_from_guess!(obj, g, vVec);
            @test mdl.check_own_calibrated_params(obj, get_pvector(obj));
            @test mdl.check_own_fixed_params(obj, get_pvector(obj));
        end

        # The same in a single convenience function, one object at a time
        # Just for testing
        ModelParams.set_params_from_guess!(m, g, vVec);
        @test objV[1].x ≈ dictV[1][:x];
        @test objV[1].y ≈ dictV[1][:y];
        @test objV[3].x ≈ dictV[3][:x];
        vVec2 = get_values(m, g);
        @test isapprox(vVec, vVec2);


        # change values
        # v1 = get_values(vVec);
        # set_values!(vVec, v1);
        # @test isapprox(v1, get_values(vVec));
        # v2 = perturb_guess(m, v1, 0.1);
        # set_values!(vVec, v2);
        # v2 = get_values(vVec);
        # @test !isapprox(v1, v2);
        # set_params_from_guess!(m, vVec);

        # this must cleanly mimick what happens with the solver ++++++
        # get it from CollegeStrat

        # vv = ModelParams.make_vector(m.o2.pvec, isCalibrated);
        # d22, nUsed2 = ModelParams.vector_to_dict(m.o2.pvec, vv, isCalibrated;
        #     startIdx = nUsed11 + 1);
        # @test d22[:a] == d2[:a]
        # @test d22[:b] == d2[:b]
        # ModelParams.set_values_from_dict!(m.o2.pvec, d22);
        # ModelParams.set_own_values_from_pvec!(m.o2, isCalibrated);
        # @test m.o2.a ≈ d2[:a]
        # @test m.o2.b ≈ d2[:b]
        # # Last object: everything should be used up
        # @test length(vAll) == nUsed2

        # # Test changing parameters
        # d22[:a] = 59.34;
        # ModelParams.set_own_values_from_dict!(m.o2, d22);
        # @test m.o2.a ≈ d22[:a]

        # d22[:b] .+= 3.8;
        # ModelParams.set_values_from_dict!(m.o2.pvec, d22);
        # ModelParams.set_own_values_from_pvec!(m.o2, isCalibrated);
        # @test m.o2.b ≈ d22[:b]
    end
end


function set_status_test()
    @testset "Set calibration status" begin
        m = init_test_model();
        nCal, _ = n_calibrated_params(m; isCalibrated = true);
        nFixed, _ = n_calibrated_params(m; isCalibrated = false);
        set_calibration_status_all_params!(m, true);
        nCal2, _ = n_calibrated_params(m; isCalibrated = true);
        @test nCal2 == nCal + nFixed;
        set_calibration_status_all_params!(m, false);
        nCal2, _ = n_calibrated_params(m; isCalibrated = true);
        @test nCal2 == 0;

        set_default_values_all_params!(m);
        pV = mdl.all_params(m);
        @test length(pV) == nCal + nFixed;
        for p in pV
            @test value(p) ≈ mdl.default_value(p);
        end
    end
end


function set_values_test()
    @testset "set values" begin
        m = init_test_model();
        pvecV = collect_pvectors(m);
        g = make_guess(m);
        guessV = ModelParams.get_values(m, g);

        # Change values arbitrarily. Need a copy of the model object; otherwise `pvec` is changed
        m2 = init_test_model();
        @test ModelParams.params_equal(m, m2);
        guess2V = ModelParams.perturb_guess_vector(m2, g, guessV, 0.1; dIdx = 4);
        set_params_from_guess!(m2, g, guess2V);
        @test !params_equal(m, m2);
        # guess2 = perturb_guess(m2, vv, 0.1; dIdx = 4);
        # @test isapprox(values(guess2), guess2V, atol = 1e-6)

        m2 = init_test_model();
        @test ModelParams.params_equal(m, m2);
        # guess2V = ModelParams.perturb_guess(m2, guessV, 0.1);
        # guess2 = perturb_guess(m2, vv, 0.1);
        # @test isapprox(values(guess2), guess2V, atol = 1e-6)
        
        # Two interfaces for setting parameters
        # ModelParams.set_params_from_guess!(m2, guess2V);
        # guess3 = make_guess(m2);
        ModelParams.set_params_from_guess!(m2, g, guessV);
        guess4V = get_values(m2, g);
        @test isapprox(guessV, guess4V)
        @test ModelParams.params_equal(m, m2);

        # Restore values from pvectors
        ModelParams.set_values_from_pvectors!(m2, pvecV, true);
        # Check that we get the same guessV
        guess5V = get_values(m2, g);
        @test isapprox(guessV, guess5V);

        m3 = init_test_model();
        perturb_params(m3, g, 0.1);
        @test !params_equal(m, m3)
        guess6V = get_values(m3, g);
        @test !isapprox(guess6V, guess5V; atol = 1e-5)
    end
end


## Model object -> Dict and back
function dict_test()
    @testset "Dict" begin
        m = init_test_model();
        g = make_guess(m);
        guessV = get_values(m, g);
        pvecV = collect_pvectors(m);
        d = make_dict(pvecV; isCalibrated = true);

        # Change parameters
        guess3V = mdl.perturb_guess_vector(m, g, guessV, 0.1);
        ModelParams.set_params_from_guess!(m, g, guess3V);
        guess5V = get_values(m, g);
        @test isapprox(guess5V, guess3V)

        # Restore the original parameters from Dict
        ModelParams.set_values_from_dicts!(m, d; isCalibrated = true);
        guess4V = get_values(m, g);
        @test isapprox(guess4V, guessV)
    end
end


@testset "Model" begin
    report_test();
    model_test();
    set_status_test();
    set_values_test();
    dict_test()
end


# -------------