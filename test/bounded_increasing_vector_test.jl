function make_bounded_test_vector(increasing :: Bool)
    ownId = ObjectId(:test1);
    dxV = [0.5, 0.2, 0.7];
    iv = BoundedVector(ownId, ParamVector(ownId), increasing, 3.0, 7.0, dxV);
    set_pvector!(iv);
    return iv
end


@testset "BoundedVector" begin
    for increasing = [false, true]
        iv = make_bounded_test_vector(increasing);
        n = length(iv);
        xV = values(iv);
        @test length(xV) == n
        if increasing
            @test all(diff(xV) .> 0.0)
        else
            @test all(diff(xV) .< 0.0)
        end
        @test all(xV .<= ub(iv))
        @test all(xV .>= lb(iv))

        for j = 1 : n
            @test values(iv, j) == xV[j]
        end
    end
end


# ------------------