## Test transformations
using ModelParams, Test

function transform_test(tr, pValue)
    @testset "Transformations" begin
        p = Param(:p1, "p1", "p1", pValue, pValue .+ 0.1, 
            -ones(size(pValue)), ones(size(pValue)),
            true);
        guess = transform_param(tr, p);
        @test all(guess .<= param_ub(tr));
        @test all(guess .>= param_lb(tr));
        pValue2 = untransform_param(tr, p, guess);
        @test all(pValue2 .≈ pValue)
        @test size(pValue2) == size(pValue)
    end
end

@testset "Transformations" begin
    pValue = [-0.8 0.3 0.0;  0.9 -0.9 0.2];
    tr = LinearTransformation{Float64}();
    transform_test(tr, pValue);
    transform_test(tr, fill(0.6, 1));
end

# -------------