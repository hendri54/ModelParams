using EconometricsLH, ModelParams

function deviation_test()
    @testset "Deviation" begin
        d1 = ModelParams.empty_deviation();
        @test isempty(d1);

        dV = [make_deviation(1), make_matrix_deviation(1)];

        for d in dV
            mSizeV = size(get_model_values(d));
            println("Model size:  $mSizeV");
            @test !isempty(d)

            sDev, devStr = scalar_dev(d);
            @test isa(sDev, Float64);
            @test isa(devStr, AbstractString)
            
            dStr = ModelParams.short_display(d);
            @test dStr[1:4] == "dev1"
            println("--- Showing deviation")
            show_deviation(d);
            show_deviation(d, showModel = false);

            wtV = get_data_values(d) .+ 0.1;
            ModelParams.set_weights!(d, wtV);
            @test get_weights(d) ≈ wtV

            modelV = get_model_values(d; matchData = true);
            @test size(modelV) == size(get_data_values(d))

            modelV = get_model_values(d) .+ 0.2;
            ModelParams.set_model_values(d, modelV);
            @test get_model_values(d) ≈ modelV;
        end
    end 
end


function penalty_test()
    @testset "Penalty Deviation" begin
        for insideBounds = [true, false]
            d = make_penalty_deviation(1, insideBounds);
            @test !isempty(d)

            scalarDev, devStr = scalar_dev(d);
            @test isa(scalarDev, Float64);
            @test isa(devStr, AbstractString)
            if insideBounds
                @test scalarDev == 0.0
            else
                @test scalarDev > 0.0
            end
            
            dStr = ModelParams.short_display(d);
            @test dStr[1:4] == "dev1"
            println("--- Showing deviation")
            show_deviation(d);
            show_deviation(d, showModel = false);
        end
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
        show_deviation(d, showModel = false);
    end
end


function regression_dev_test()
    d1 = ModelParams.empty_regression_deviation();
    @test isempty(d1);

    d = make_regression_deviation(1);
    dNameV, dCoeffV, dSeV = get_unpacked_data_values(d);
    @test length(dCoeffV) == length(dSeV) > 1
    @test all(dSeV .> 0.0)

    show_deviation(d);
    show_deviation(d, showModel = false);

    mNameV, mCoeffV, mSeV = get_unpacked_model_values(d);
    @test length(mCoeffV) == length(mSeV) == length(dCoeffV)

    nameV = get_names(d.dataV);
    mRegr = RegressionTable(nameV, mCoeffV .+ 1.0, mSeV .+ 1.0)
    set_model_values(d, mRegr);
    mName2V, mCoeff2V, mSe2V = get_unpacked_model_values(d);
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
        # Not sorted, so the following test does not work
        scalarDev1, _ = scalar_dev(dev1);
        # @test devV[1] == scalarDev1

        sds = scalar_dev_dict(d);
        @test isa(sds, Dict{Symbol, ModelParams.ValueType})
        @test length(sds) == 3
        @test sds[ModelParams.name(dev1)] ≈ scalarDev1
        @test sort(devV) ≈ sort(collect(values(sds)))


        scalarDev = scalar_deviation(d);
        @test isa(scalarDev, Float64)
        @test scalarDev >= 0.0

        @test isempty(retrieve(d, :notThere))
        dev = retrieve(d, :d1);
        @test dev.name == :d1
    end
end


@testset "Deviations" begin
    penalty_test()
    deviation_test()
    scalar_dev_test()
    regression_dev_test()
    dev_vector_test()
end

# -------------