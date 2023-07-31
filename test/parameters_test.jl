using ModelParams, Random, Test

mdl = ModelParams;

function param_test()
    @testset "Param" begin
        pValue = [1.1 2.2; 3.3 4.4];
        defaultValue = pValue .+ 0.1;

        # Simple constructor
        p1 = make_param(:p1, pValue; description = "param1",
            symbol = "\$p_{1}\$", isCalibrated = true);
        set_default_value!(p1, defaultValue);
        # show(p1);
        @test pvalue(p1) == pValue;
        @test size(p1.lb) == size(pValue);
        fix!(p1);
        @test p1.isCalibrated == false;
        @test pvalue(p1) == defaultValue;
        calibrate!(p1);
        @test p1.isCalibrated == true;
        @test pvalue(p1) == pValue;
        validate(p1);

        # Full constructor
        pValue2 = 1.23;
        lb2 = -2.8;
        ub2 = 7.3;
        p2 = Param(:p2, "param2", "\$p_{2}\$", pValue2, pValue2 + 0.5,
            lb2, ub2, true);
        # show(p2)
        @test pvalue(p2) == pValue2;
        @test size(p2.ub) == size(pValue2);
        newValue = 9.27;
        set_calibrated_value!(p2, newValue);
        @test calibrated_value(p2) ≈ newValue;
        str1 = ModelParams.short_string(p2);
        @test startswith(str1,  "p2: 9.27");

        update!(p2, value = 98.2);
        @test pvalue(p2) == 98.2
        @test p2.lb == lb2
        update!(p2, lb = -2.0, ub = 8.0);
        validate(p2);
        @test p2.lb == -2.0;
        @test pvalue(p2) == 98.2;
    end
end

function vec1_test()
    @testset "Vector of length 1" begin
        pValue = fill(1.2, 1);
        p1 = Param(:p1, "param1", "\$p_{1}\$", pValue, pValue .+ 0.1, 
            fill(0.1, 1), fill(5.0, 1), true);
        show(p1);
        @test isequal(pValue, pvalue(p1));

        set_random_value!(p1, MersenneTwister(12));
        newValue = pvalue(p1);
        @test size(newValue) == size(pValue);
    end
end

function array_test(p)
    @testset "Mapped param $p" begin
        @test validate(p);
        @test short_description(p) isa String;
        @test size(calibrated_value(p)) == size(default_value(p));
        @test size(calibrated_lb(p)) == size(calibrated_ub(p)) == size(calibrated_value(p));
        closeToLb = mdl.close_to_lb(p; rtol = 0.1);
        closeToUb = mdl.close_to_ub(p; rtol = 0.1);
        @test mdl.close_to_bounds(p; rtol = 0.1) == (closeToLb || closeToUb);
        isCal = is_calibrated(p);
        mdl.set_calibration_status!(p, !isCal);
        @test is_calibrated(p) == !isCal;

        calibrate!(p);
        pVal = pvalue(p);
        calVal = calibrated_value(p);
        set_default_value!(p, calVal .- 0.1);
        @test pvalue(p) == pVal;
        @test default_value(p) ≈ calVal .- 0.1;
        fix!(p);
        @test !all(isapprox.(pvalue(p), pVal));

        pVal = pvalue(p);
        if p isa MParam
            pMap = mdl.pmeta(p);
            if pMap isa IncreasingMap
                @test all(scalar_lb(pMap) .<= pVal .<= scalar_ub(pMap));
            end
        end
        
        lbnd = calibrated_lb(p) .+ 0.1;
        ubnd = calibrated_ub(p) .+ 0.2;
        set_bounds!(p; lb = lbnd, ub = ubnd);
        @test calibrated_lb(p) ≈ lbnd;
        @test calibrated_ub(p) ≈ ubnd;

        pValue = pvalue(p);
        if p isa Param  # should also work for MParam +++++
            set_random_value!(p, MersenneTwister(12));
            newValue = pvalue(p);
            @test size(newValue) == size(pValue);
        end
    end
end

function make_test_array_param()
    v = [1.0 2.0; 3.0 4.0; 5.0 6.0];
    p = Param(:x, "x", "x", v, v .+ 0.1, v .- 2.0, v .+ 2.0, true);
    return p
end


@testset "Parameters" begin
    param_test();
    vec1_test();
    for p in (
        make_test_array_param(),
        mdl.make_test_mapped_param(:m1, (3,), IdentityMap()),
        mdl.make_test_mapped_param(:m2, nothing, ScalarMap()),
        mdl.make_test_mapped_param(:m2, nothing, mdl.make_test_grouped_map()),
        mdl.make_test_mapped_param(:m4, (3,), IncreasingMap(2.0, 5.0)),
        mdl.make_test_mapped_param(:m4, (3,), DecreasingMap(2.0, 5.0)),
        mdl.make_test_mapped_param(:m5, (4,), BaseAndDeviationsMap()),
        # mdl.make_test_cal_array(:x, 2),
        mdl.make_test_bvector(:x; increasing = :increasing),
        mdl.make_test_bvector(:x; increasing = :decreasing),
        )
        array_test(p);
    end
end

# ------------
