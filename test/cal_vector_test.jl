using ModelParams, Random, Test

mdl = ModelParams;

# Needs its own test, separate from general param test.
# Because it's possible here to calibrate only some values.
function cal_vector_test(cal)
    @testset "CalVector $cal" begin
        p = mdl.make_test_cal_vector(cal);
        @test validate(p);
        v = pvalue(p);
        vCal = calibrated_value(p);
        if cal == :none
            @test ismissing(vCal);
            @test n_calibrated(p) == 0;

        else
            @test n_calibrated(p) > 0;
            @test size(default_value(p)) == (n_calibrated(p), );
            vNew = default_value(p) .+ 0.1;
            set_calibrated_value!(p, vNew);
            @test calibrated_value(p) == vNew;
            dvNew = default_value(p) .- 0.1;
            set_default_value!(p, dvNew);
            @test default_value(p) == dvNew;
        end

        calibrate!(p);
        @test size(calibrated_value(p)) == size(v);

        fix!(p);
        @test ismissing(calibrated_value(p));
        @test n_calibrated(p) == 0;
    end
end

@testset "CalVector" begin
    for cal in (:all, :none, :some)
        cal_vector_test(cal);
    end
end

# ---------------