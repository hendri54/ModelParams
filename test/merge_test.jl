"""
    merge_object_arrays!
"""

mutable struct MoaTest
    x
    y
    z
    a
end

function merge_object_arrays_test()
    n = 17;
    Random.seed!(123);
    x = rand(n, 2);
    y = rand(n, 3);
    z = rand(n, 3, 2);
    a = rand(n);
    oTg = MoaTest(x, y, z, a);

    idxV = [3,4,8];
    nSrc = length(idxV);
    x2 = rand(nSrc, 2);
    y2 = 9.3;
    z2 = rand(nSrc, 3, 2);
    a2 = rand(nSrc);
    oSrc = MoaTest(x2, y2, z2, a2);

    ModelParams.merge_object_arrays!(oSrc, oTg, idxV, false, dbg = true);

    @test oTg.x[idxV,:] ≈ x2
    @test oTg.y ≈ y  # Skipped field; not array in source
    @test oTg.z[idxV,:,:] ≈ z2
    @test oTg.a[idxV] ≈ a2
    return true
end

