using Test, ModelParams

## Parameter vector test
import ModelParams.get_pvector

## --------------  Setup

# Make a ParamVector for testing
# Alternates between calibrated and fixed parameters
function init_pvector(n :: Integer; objId :: Symbol = :obj1,
    offset :: Float64 = 0.0)

    pv = ParamVector(ObjectId(objId));
    for i1 = 1 : n
        p = init_parameter(i1; offset = offset);
        if isodd(i1)
            calibrate!(p);
        end
        ModelParams.append!(pv, p);
    end
    return pv
end

function init_parameter(i1 :: Integer;  offset :: Float64 = 0.0)
    pSym = Symbol("p$i1");
    pName = "param$i1";
    pDescr = "sym$i1";
    valueM = (offset + i1) .+ collect(1 : i1) * [1.0 2.0];
    return Param(pSym, pName, pDescr, valueM)
end


## --------------  Tests

## Test basic operations
function pvectorTest()
    @testset "Pvector" begin
        pv = ParamVector(ObjectId(:pv1));
        show(pv);
        @test length(pv) == 0

        p = Param(:p1, "param1", "sym1", [1.2 3.4; 4.5 5.6])
        ModelParams.append!(pv, p)
        @test length(pv) == 1
        nParam, nElem = ModelParams.n_calibrated_params(pv, p.isCalibrated);
        @test nParam == 1
        @test nElem == 4

        pOut, idx = retrieve(pv, :p11)
        @test idx == 0
        @test !param_exists(pv, :p11)
        pOut, idx = retrieve(pv, :p1)
        @test idx == 1
        @test pOut.name == :p1
        @test param_exists(pv, :p1)

        p = Param(:p2, "param2", "sym2", [2.2 4.4; 4.5 5.6])
        ModelParams.append!(pv, p)
        show(pv)
        ModelParams.remove!(pv, :p1)
        @test length(pv) == 1
        @test param_exists(pv, :p2)
        @test !param_exists(pv, :p1)

        # Test replace
        p2 = Param(:p2, "param2", "sym2", 1.0);
        ModelParams.replace!(pv, p2);
        p22, _ = retrieve(pv, :p2);
        @test p22.value == 1

        # Retrieve non-existing
        p3, idx = retrieve(pv, :notThere);
        @test isnothing(p3) && (idx == 0)

        # Parameter value
        pValue = param_value(pv, :p2);
        @test pValue == p2.value
        pValue = param_value(pv, :notThere);
        @test isnothing(pValue)
    end
end


function iter_test()
    @testset "Iteration" begin
        n = 5;
        pv = init_pvector(n);
        j = 0;
        for p in pv
            j += 1;
            @test isa(p, Param);
        end
        @test j == n
	end
end


## Vector to Dict and back
function pvectorDictTest()
    @testset "Pvector Dict" begin
        pv = init_pvector(3);
        d = make_dict(pv, true)
        p1, _ = retrieve(pv, :p1);
        p3, _ = retrieve(pv, :p3);
        @test d[:p1] == p1.value
        @test d[:p3] == p3.value
        @test length(d) == 2

        # Make vector and its inverse (make Dict from vector)
        isCalibrated = true;
        # Vector contains transformed parameters
        vv = make_vector(pv, isCalibrated);
        @test isa(ModelParams.values(vv),  Vector{Float64})
        p1Value = transform_param(pv.pTransform, p1);
        p3Value = transform_param(pv.pTransform, p3);
        @test ModelParams.values(vv) == vcat(vec(p1Value), vec(p3Value))
        @test all(ModelParams.lb(vv) .≈ pv.pTransform.lb)

        pDict, _ = vector_to_dict(pv, vv, isCalibrated);
        @test length(pDict) == 2
        @test pDict[:p1] == p1.value
        @test pDict[:p3] == p3.value
    end
end


function set_values_test()
    @testset "Set values" begin
        isCalibrated = true;
        pv = init_pvector(7);
        d = make_dict(pv, isCalibrated);
        # Change values in `pv`
        pv2 = init_pvector(7; offset = 1.0);
        # d2 = make_dict(pv2, isCalibrated);
        ModelParams.set_own_values_from_pvec!(pv, pv2, true);
        # Check that values are now higher using a `Dict`
        d3 = make_dict(pv, isCalibrated);
        @test isequal(keys(d), keys(d3))
        for key in keys(d)
            @test all(d3[key] .> d[key])
        end
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
        pv = init_pvector(9);

        idxV = ModelParams.indices_calibrated(pv, true);
        for idx in idxV
            p = pv[idx];
            @test p.isCalibrated
        end

        pvEmpty = ParamVector(ObjectId(:pvEmpty));
        @test isempty(pvEmpty)
        @test isempty(ModelParams.indices_calibrated(pvEmpty, false))

        println("-----  Calibrated parameters")
        ModelParams.report_params(pv, true)
        nParam, nElem = ModelParams.n_calibrated_params(pv, true);
        @test nParam == 5
        @test nElem > 10

        println("-----  Fixed parameters")
        ModelParams.report_params(pv, false)
        nParam, nElem = ModelParams.n_calibrated_params(pv, false);
        @test nParam == 4
        @test nElem > 8
    end
end


# wrong place +++
function pv_vector_test()
    @testset "Vector of ParamVector" begin
        n = 3;
        pvv = Vector{ParamVector}(undef, n);
        for j = 1 : n
            pvv[j] = init_pvector(j + 2; objId = Symbol("obj$j"));
        end

        d = ModelParams.make_dict(pvv);
        @test length(d) == n
        for j = 1 : n
            objId = make_string(get_object_id(pvv[j]));
            @test haskey(d, objId)
            @test isequal(d[objId],  make_dict(pvv[j], true))
        end
    end
end


@testset "ParamVector" begin
    pvectorTest()
    iter_test()
    get_pvector_test()
    pvectorDictTest()
    set_values_test()
    report_test()
    pv_vector_test()
end

# -------------
