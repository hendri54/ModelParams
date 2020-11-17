using ModelObjectsLH, ModelParams, Test

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
            @test ModelParams.check_values(iv, xV)

            for j = 1 : n
                @test values(iv, j) == xV[j]
            end

            xNewV = xV .+ 0.05;
    		fix_values!(iv, xNewV);
            x2V = values(iv);
            @test isapprox(xNewV, x2V)
        end
    end
end


# ------------------