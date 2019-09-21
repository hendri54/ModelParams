## Test transformations

@testset "Transformations" begin
    pValue = [-0.8 0.3 0.0;  0.9 -0.9 0.2];
    p = Param(:p1, "p1", "p1", pValue, pValue .+ 0.1, 
        -ones(size(pValue)), ones(size(pValue)),
        true);
    tr = LinearTransformation(1.0, 2.0);

    guess = transform_param(tr, p);
    @test all(guess .<= tr.ub)
    @test all(guess .>= tr.lb)
    value = untransform_param(tr, p, guess);
    @test all(value .≈ pValue)

end

# -------------