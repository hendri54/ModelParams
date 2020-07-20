using ModelParams, Test

function make_bounded_test_vector(vLength :: Integer, increasing :: Bool)
    ownId = ObjectId(:test1);
    if vLength > 1
        dxV = collect(range(0.4, 0.2, length = vLength));
    else
        dxV = [0.4];
    end
    iv = BoundedVector(ownId, ParamVector(ownId), increasing, 3.0, 7.0, dxV);
    set_pvector!(iv);
    return iv
end


@testset "BoundedVector" begin
    for vLength in [1, 3]
        for increasing in [false, true]
            iv = make_bounded_test_vector(vLength, increasing);
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
end


# ------------------