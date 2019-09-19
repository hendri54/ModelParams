using EconometricsLH

## -----------  Make deviations for testing
# Names are :d1 etc

function make_deviation(devNo :: Integer)
    dataV = devNo .+ collect(range(2.1, 3.4, length = 5));
    modelV = dataV .+ 0.7;
    wtV = dataV .+ 0.9;
    name, shortStr, longStr, fmtStr = dev_info(devNo);
    d = Deviation(name = name, 
        modelV = modelV, dataV = dataV, wtV = wtV,
        shortStr = shortStr, longStr = longStr);
    return d;
end

function make_scalar_deviation(devNo :: Integer)
    name, shortStr, longStr, fmtStr = dev_info(devNo);
    modelV = devNo * 1.1;
    dataV = devNo * 2.2;
    return ScalarDeviation(name = name, modelV = modelV, 
        dataV = dataV, shortStr = shortStr, 
        longStr = longStr)
end

function make_regression_deviation(devNo :: Integer)
    name, shortStr, longStr, fmtStr = dev_info(devNo);
    nc = devNo + 2;
    coeffNameV = Symbol.("beta" .* string.(1 : nc));
    mCoeffV = collect(range(0.1, 0.9, length = nc));
    mSeV = collect(range(0.3, 0.1, length = nc));
    rModel = RegressionTable(coeffNameV, mCoeffV, mSeV);
    rData = RegressionTable(coeffNameV, mCoeffV .+ 0.1, mSeV .+ 0.2);
    return RegressionDeviation(name = name,
        shortStr = shortStr, longStr = longStr,
        modelV = rModel, dataV = rData)
end

function dev_info(devNo :: Integer)
    name = Symbol("d$devNo");
    shortStr = "dev$devNo";
    longStr = "Deviation $devNo"
    fmtStr = "%.2f";
    return name, shortStr, longStr, fmtStr
end


## ------------  Test deviations

function deviation_test()
    @testset "Deviation" begin
        d1 = ModelParams.empty_deviation();
        @test isempty(d1);

        d = make_deviation(1);
        @test !isempty(d)
        sDev, devStr = scalar_dev(d);
        @test isa(sDev, Float64);
        @test isa(devStr, AbstractString)
        dStr = ModelParams.short_display(d);
        @test dStr[1:4] == "dev1"
        println("--- Showing deviation")
        show_deviation(d);

        wtV = d.dataV .+ 0.1;
        ModelParams.set_weights!(d, wtV);
        @test d.wtV ≈ wtV

        modelV = d.dataV .+ 0.2;
        ModelParams.set_model_values(d, modelV);
        @test d.modelV ≈ modelV;

        d2 = Deviation(name = :d2, modelV = rand(4,3), dataV = rand(4,3));
        show_deviation(d2);
    end 
end


function scalar_dev_test()
    @testset "ScalarDeviation" begin
        d1 = ModelParams.empty_scalar_deviation();
        @test isempty(d1);

        d = make_scalar_deviation(1);
        @test !isempty(d);
        sDev, devStr = scalar_dev(d);
        @test isa(sDev, Float64);
        @test isa(devStr, AbstractString)
        dStr = ModelParams.short_display(d);
        @test dStr[1:4] == "dev1"

        modelV = d.dataV .+ 0.2;
        ModelParams.set_model_values(d, modelV);
        @test d.modelV ≈ modelV;

        println("--- Showing scalar deviation")
        show_deviation(d);
    end
end


function regression_dev_test()
    d1 = ModelParams.empty_regression_deviation();
    @test isempty(d1);

    d = make_regression_deviation(1);
    dNameV, dCoeffV, dSeV = get_data_values(d);
    @test length(dCoeffV) == length(dSeV) > 1
    @test all(dSeV .> 0.0)

    show_deviation(d);

    mNameV, mCoeffV, mSeV = get_model_values(d);
    @test length(mCoeffV) == length(mSeV) == length(dCoeffV)

    nameV = get_names(d.dataV);
    mRegr = RegressionTable(nameV, mCoeffV .+ 1.0, mSeV .+ 1.0)
    set_model_values(d, mRegr);
    mName2V, mCoeff2V, mSe2V = get_model_values(d);
    @test mCoeff2V ≈ mCoeffV .+ 1.0

    scalarDev, scalarStr = scalar_dev(d);
    @test scalarDev > 0.0
    @test isa(scalarStr, String)

    mRegr = RegressionTable(nameV, dCoeffV, dSeV .+ 0.1);
    set_model_values(d, mRegr);
    scalarDev, _ = scalar_dev(d);
    @test scalarDev ≈ 0.0
end


function dev_vector_test()
    @testset "DevVector" begin
        d = DevVector()
        @test length(d) == 0
        dev1 = make_deviation(1);
        ModelParams.append!(d, dev1);
        @test length(d) == 1

        dev2 = make_scalar_deviation(2);
        ModelParams.append!(d, dev2);
        @test length(d) == 2
        show(d);

        dev22 = ModelParams.retrieve(d, :d2);
        @test !isempty(dev22)
        @test dev22.dataV ≈ dev2.dataV
        @test ModelParams.dev_exists(d, :d2)
        @test !ModelParams.dev_exists(d, :notThere)

        modelV = dev22.dataV .+ 1.3;
        ModelParams.set_model_values(d, :d2, modelV);
        dev22 = ModelParams.retrieve(d, :d2);
        @test dev22.modelV ≈ modelV

        dev3 = make_deviation(3);
        ModelParams.append!(d, dev3);
        wtV = dev3.dataV .+ 2.3;
        ModelParams.set_weights!(d, :d3, wtV);
        dev3 = ModelParams.retrieve(d, :d3);
        @test dev3.wtV ≈ wtV

        devV = scalar_devs(d);
        @test length(devV) == 3;
        scalarDev1, _ = scalar_dev(dev1);
        @test devV[1] == scalarDev1

        scalarDev = scalar_deviation(d);
        @test isa(scalarDev, Float64)
        @test scalarDev >= 0.0

        @test isempty(retrieve(d, :notThere))
        dev = retrieve(d, :d1);
        @test dev.name == :d1
    end
end
