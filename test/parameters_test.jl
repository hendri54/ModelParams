using ModelParams, Random, Test

mdl = ModelParams;

function param_test()
    @testset "Param" begin
        pValue = [1.1 2.2; 3.3 4.4]

        # Simple constructor
        p1 = Param(:p1, "param1", "\$p_{1}\$", pValue);
        # show(p1);
        @test pvalue(p1) == pValue;
        @test size(p1.lb) == size(pValue);
        calibrate!(p1);
        @test p1.isCalibrated == true;
        fix!(p1);
        @test p1.isCalibrated == false;
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
        set_value!(p2, newValue);
        @test pvalue(p2) ≈ newValue;
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
    @testset "Array param $p" begin
        @test validate(p);
        @test size(pvalue(p)) == size(default_value(p));
        @test size(param_lb(p)) == size(param_ub(p)) == size(pvalue(p));
        closeToLb = mdl.close_to_lb(p; rtol = 0.1);
        closeToUb = mdl.close_to_ub(p; rtol = 0.1);
        @test mdl.close_to_bounds(p; rtol = 0.1) == (closeToLb || closeToUb);
        isCal = is_calibrated(p);
        mdl.set_calibration_status!(p, !isCal);
        @test is_calibrated(p) == !isCal;
        
        lbnd = param_lb(p) .+ 0.1;
        ubnd = param_ub(p) .+ 0.2;
        set_bounds!(p; lb = lbnd, ub = ubnd);
        @test param_lb(p) ≈ lbnd;
        @test param_ub(p) ≈ ubnd;

        pValue = pvalue(p);
        if p isa Param
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
        mdl.make_test_cal_array(:x, 2),
        mdl.make_test_bvector(:x; increasing = :increasing),
        mdl.make_test_bvector(:x; increasing = :decreasing),
        )
        array_test(p);
    end
end

# ------------
