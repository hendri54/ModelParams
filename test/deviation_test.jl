## Make deviations for testing
# Names are :d1 etc
function make_deviation(devNo :: Integer)
    dataV = devNo .+ collect(range(2.1, 3.4, length = 5));
    modelV = dataV .+ 0.7;
    wtV = dataV .+ 0.9;
    # scaleFactor = 12.0;
    shortStr = "dev$devNo";
    longStr = "Deviation $devNo"
    fmtStr = "%.2f";
    d = Deviation(Symbol("d$devNo"), modelV, dataV, wtV,
        shortStr, longStr, fmtStr);
    return d;
end

function deviationTest()
    d1 = Deviation();
    @test isempty(d1);

    d = make_deviation(1);
    @test !isempty(d)
    sDev, devStr = scalar_dev(d);
    @test isa(sDev, Float64);
    @test isa(devStr, AbstractString)
    dStr = ModelParams.short_display(d);
    @test dStr[1:4] == "dev1"

    wtV = d.dataV .+ 0.1;
    ModelParams.set_weights!(d, wtV);
    @test d.wtV ≈ wtV

    modelV = d.dataV .+ 0.2;
    ModelParams.set_model_values(d, modelV);
    @test d.modelV ≈ modelV;

    return true
end


function devVectorTest()
    d = DevVector()
    @test length(d) == 0
    dev1 = make_deviation(1);
    ModelParams.append!(d, dev1);
    @test length(d) == 1

    dev2 = make_deviation(2);
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

    wtV = dev22.dataV .+ 2.3;
    ModelParams.set_weights!(d, :d2, wtV);
    dev22 = ModelParams.retrieve(d, :d2);
    @test dev22.wtV ≈ wtV

    devV = scalar_devs(d);
    @test length(devV) == 2;
    scalarDev1, _ = scalar_dev(dev1);
    @test devV[1] == scalarDev1

    @test isempty(retrieve(d, :notThere))
    dev = retrieve(d, :d1);
    @test dev.name == :d1
    return true
end
