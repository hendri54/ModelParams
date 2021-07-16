using ModelObjectsLH, ModelParams, Random, Test

mdl = ModelParams;

function calibrated_array_test(N)
    rng = MersenneTwister(23);
    @testset "Calibrated Array $N" begin
        switches = mdl.make_test_calibrated_array_switches(N);
        # objId = ObjectId(:test);
        # sizeV = 2 : (1 + N);
        # sz = (sizeV..., );

        # T1 = Float32;
        # defaultValueM = randn(rng, T1, sz);
        # lbM = defaultValueM .- one(T1);
        # ubM = defaultValueM .+ one(T1);
        # isCalM = defaultValueM .> 0.0;

        # switches = CalibratedArraySwitches(objId, defaultValueM, lbM, ubM, isCalM);
        ca = CalibratedArray(switches);

        @test size(ca) == size(switches.defaultValueM);
        @test validate_ca(ca);

        # Change calibrated values
        pvec = get_pvector(ca);
        p = retrieve(pvec, :calValueV);
        p.value .+= 0.1;
        ca.calValueV = copy(p.value);

        @test mdl.check_fixed_values(ca);
    end
end

function all_fixed_test(N)
    @testset "All fixed" begin
        switches = mdl.make_test_calibrated_array_switches(N; allFixed = true);
        ca = CalibratedArray(switches);
        @test validate_ca(ca);
        valueM = ModelParams.values(ca);
        @test isapprox(valueM, switches.defaultValueM);
    end
end

@testset "Calibrated Array" begin
    for N = 1 : 3
        calibrated_array_test(N);
        all_fixed_test(N);
    end
end

# --------------