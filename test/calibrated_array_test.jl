using ModelObjectsLH, ModelParams, Random, Test

mdl = ModelParams;

function calibrated_array_test(N)
    rng = MersenneTwister(23);
    @testset "Calibrated Array $N" begin
        objId = ObjectId(:test);
        sizeV = 2 : (1 + N);
        sz = (sizeV..., );

        T1 = Float32;
        defaultValueM = randn(rng, T1, sz);
        lbM = defaultValueM .- one(T1);
        ubM = defaultValueM .+ one(T1);
        isCalM = defaultValueM .> 0.0;

        switches = CalibratedArraySwitches(objId, defaultValueM, lbM, ubM, isCalM);
        ca = CalibratedArray(switches);

        @test size(ca) == size(defaultValueM);
        @test validate_ca(ca);

        # Change calibrated values
        pvec = get_pvector(ca);
        p = retrieve(pvec, :calValueV);
        p.value .+= T1(0.1);
        ca.calValueV = copy(p.value);

        @test mdl.check_fixed_values(ca);
    end
end

@testset "Calibrated Array" begin
    for N = 1 : 3
        calibrated_array_test(N);
    end
end

# --------------