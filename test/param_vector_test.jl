using Test, ModelObjectsLH,  ModelParams

## Parameter vector test
import ModelParams.get_pvector

mdl = ModelParams;

## Test basic operations
function pvectorTest()
    @testset "Pvector" begin
        pv = ParamVector(ObjectId(:pv1));
        # println(pv);
        @test length(pv) == 0

        p = Param(:p1, "param1", "sym1", [1.2 3.4; 4.5 5.6])
        ModelParams.append!(pv, p)
        @test length(pv) == 1
        nParam, nElem = mdl.n_calibrated_params(pv; isCalibrated = is_calibrated(p));
        @test nParam == 1
        @test nElem == 4

        pOut = retrieve(pv, :p11)
        @test isnothing(pOut);
        @test !param_exists(pv, :p11)
        pOut = retrieve(pv, :p1)
        @test pOut.name == :p1
        @test pv[1].name == :p1;
        @test param_exists(pv, :p1)

        p = Param(:p2, "param2", "sym2", [2.2 4.4; 4.5 5.6])
        ModelParams.append!(pv, p)
        # println(pv)
        ModelParams.remove!(pv, :p1)
        @test length(pv) == 1
        @test param_exists(pv, :p2)
        @test !param_exists(pv, :p1)

        # Test replace
        p2 = Param(:p2, "param2", "sym2", 1.0);
        ModelParams.replace!(pv, p2);
        p22 = retrieve(pv, :p2);
        @test ModelParams.value(p22) == 1

        # Retrieve non-existing
        p3 = retrieve(pv, :notThere);
        @test isnothing(p3);

        # Parameter value
        pValue = param_value(pv, :p2);
        @test pValue == p2.value
        pValue = param_value(pv, :notThere);
        @test isnothing(pValue)
    end
end


function set_status_test()
    @testset "Set status" begin
        n = 7;
        pvec = mdl.make_test_pvector(n);
        set_calibration_status_all_params!(pvec, false);
        @test n_calibrated_params(pvec; isCalibrated = true) == (0, 0);
        set_calibration_status_all_params!(pvec, true);
        @test n_calibrated_params(pvec; isCalibrated = true)[1] == n;

        set_default_values_all_params!(pvec);
        for p in pvec
            @test value(p) ≈ mdl.default_value(p);
        end
    end
end


function iter_test()
    @testset "Iteration" begin
        n = 5;
        pv = mdl.make_test_pvector(n);
        j = 0;
        for p in pv
            j += 1;
            @test isa(p, AbstractParam);
        end
        @test j == n
	end
end


## Vector to Dict and back
function pvectorDictTest()
    @testset "Pvector Dict" begin
        isCalibrated = true;
        pv = mdl.make_test_pvector(4);
        d = make_dict(pv; isCalibrated = true, valueType = :value);
        for pName in keys(d)
            p1 = retrieve(pv, pName);
            @test d[pName] == mdl.value(p1);
        end
        # p1 = retrieve(pv, :p1);
        # p3 = retrieve(pv, :p3);
        # @test d[:p1] == p1.value
        # @test d[:p3] == p3.value
        @test length(d) == n_calibrated_params(pv; isCalibrated = isCalibrated)[1];

        # Make vector and its inverse (make Dict from vector)
        # Vector contains transformed parameters
        vv = mdl.make_value_vector(pv, 1);
        @test isa(get_values(pv, vv),  Vector{Float64});
        pValueV = Vector{Float64}();
        for pName in keys(d)
            p1 = retrieve(pv, pName);
            pValue = transform_param(pv.pTransform, p1);
            append!(pValueV, pValue);
        end
        # p1Value = transform_param(pv.pTransform, p1);
        # p3Value = transform_param(pv.pTransform, p3);
        @test get_values(pv, vv) == pValueV
        # @test all(ModelParams.lb(vv) .≈ pv.pTransform.lb)

        # pDict, _ = vector_to_dict(pv, vv, isCalibrated);
        # @test length(pDict) == 2
        # @test pDict[:p1] == p1.value
        # @test pDict[:p3] == p3.value
    end
end


function set_values_test()
    @testset "Set values" begin
        isCalibrated = true;
        pv = mdl.make_test_pvector(7);
        d = make_dict(pv; isCalibrated, valueType = :value);
        # Change values in `pv`
        pv2 = mdl.make_test_pvector(7; offset = 1.0);
        # d2 = make_dict(pv2; isCalibrated, useValues = true);
        ModelParams.set_own_values_from_pvec!(pv, pv2, true);
        # Check that values are now higher using a `Dict`
        d3 = make_dict(pv; isCalibrated, valueType = :value);
        @test isequal(keys(d), keys(d3));
        for key in keys(d)
            @test all(d3[key] .> d[key])
        end

        p = pv[1];
        @test p isa AbstractParam;
        if default_value(p) isa Real
            lbnd = -10.0;
            ubnd = 20.0;
        else
            sz = size(default_value(p));
            lbnd = fill(-10.0, sz);
            ubnd = fill(20.0, sz);
        end
        set_bounds!(pv, p.name; lb = lbnd, ub = ubnd);
        @test mdl.lb(p) == lbnd;
        @test mdl.ub(p) == ubnd;
	end
end


function compare_test()
    @testset "Compare" begin
        pvec1 = mdl.make_test_pvector(7);
        pvec2 = mdl.make_test_pvector(7);
        pMiss1, pMiss2, pDiff = compare_params(pvec1, pvec2);
        @test isempty(pMiss1);
        @test isempty(pMiss2);
        @test isempty(pDiff);
    end
end


## Finding ParamVector in object
mutable struct M1 <: ModelObject
    objId :: ObjectId
    pvec :: ParamVector
end

mutable struct M2 <: ModelObject
    objId :: ObjectId
    x :: ParamVector
    y :: Float64
end

get_pvector(m :: M2) = m.x;

mutable struct M3 <: ModelObject
    objId :: ObjectId
    y :: Float64
end

function get_pvector_test()
    @testset "get pvector" begin
        m1 = M1(ObjectId(:m1),  ParamVector(ObjectId(:m1)));
        @test ModelParams.get_pvector(m1) == m1.pvec

        m2 = M2(ObjectId(:m2),  ParamVector(ObjectId(:m2)), 1.2);
        @test ModelParams.get_pvector(m2) == m2.x

        m3 = M3(ObjectId(:m3),  1.2);
        pvec3 = ModelParams.get_pvector(m3);
        @test length(pvec3) == 0
    end
end


function report_test()
    @testset "Pvector reporting" begin
        pv = mdl.make_test_pvector(9);

        pList = ModelParams.calibrated_params(pv; isCalibrated = true);
        for p in pList
            @test is_calibrated(p)
        end

        pvEmpty = ParamVector(ObjectId(:pvEmpty));
        @test isempty(pvEmpty)
        @test isempty(ModelParams.calibrated_params(pvEmpty; isCalibrated = false))

        println("-----  Calibrated parameters")
        ModelParams.report_params(pv, true)
        nParam, nElem = ModelParams.n_calibrated_params(pv; isCalibrated = true);
        @test nParam == 5
        @test nElem > 10

        println("-----  Fixed parameters")
        ModelParams.report_params(pv, false)
        nParam, nElem = ModelParams.n_calibrated_params(pv; isCalibrated = false);
        @test nParam == 4
        @test nElem > 8

        println("-----  Close to bounds");
        report_params(pv, true; closeToBounds = true);
    end
end


@testset "ParamVector" begin
    pvectorTest();
    set_status_test();
    iter_test()
    get_pvector_test()
    pvectorDictTest()
    set_values_test()
    report_test()
end

# -------------
