using ModelObjectsLH, ModelParams, Test

mdl = ModelParams;

function pv_collection_test()
    @testset "Main" begin
        n = 5;
        pvv = mdl.make_test_pvector_collection(n);

        @test !isempty(pvv);
        @test length(pvv) == n;

        for (objId, pvec) in pvv
            @test objId == get_object_id(pvec);
            @test has_pvector(pvv, objId);
            pv = find_pvector(pvv, objId);
            @test isequal(get_object_id(pv), objId);
        end       
    end
end

function constructors_test()
    @testset "Constructors" begin
        n = 3;
        pv = [mdl.make_test_pvector(2+j; objId = Symbol("obj$j"))  for j = 1 : n];
        pvecV = PVectorCollection(pv);
        @test length(pvecV) == n;
    end
end

function make_dict_test()
    @testset "Make Dict" begin
        n = 6;
        pvv = mdl.make_test_pvector_collection(n);
        d = mdl.make_dict(pvv; isCalibrated = true);
        @test length(d) == n
        for objIdStr in keys(d)
            objId = make_object_id(objIdStr);
            pvec = find_pvector(pvv, objId);
            @test isequal(d[objIdStr],  make_dict(pvec; isCalibrated = true, valueType = :value))
        end
    end
end

function find_param_test()
    @testset "Find param" begin
        n = 5;
        pvv = mdl.make_test_pvector_collection(n);
        d = find_param(pvv, :notThere);
        @test isempty(d);
        pName = :p4;
        d = find_param(pvv, pName);
        for (objId, p) in d
            pvec = find_pvector(pvv, objId);
            @test param_exists(pvec, pName);
        end
    end
end


@testset "PVectorCollection" begin
    constructors_test();
    pv_collection_test();
    make_dict_test();
    find_param_test();
end

# -----------