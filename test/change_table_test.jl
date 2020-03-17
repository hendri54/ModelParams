using Test, ModelParams

function change_table_test()
    @testset "Change table basics" begin
        n = 3;
        dv = make_deviation_vector(n);

        paramNameV = [:aa, :bbb, :cc, :d];
        nParam = length(paramNameV);

        ct = ModelParams.ChangeTable(dv, paramNameV);
        @test ModelParams.param_names(ct) == paramNameV
        @test ModelParams.n_params(ct) == nParam
        @test ModelParams.n_devs(ct) == length(dv)

        for j = 1 : nParam
            # Offset ensures that the first deviation is the same as the base
            dv2 = make_deviation_vector(n; offset = 0.5 * (j-1));
            ModelParams.set_param_values!(ct, j, dv2; scalarDev = nothing);
        end

        ModelParams.show_table(ct)

        pNameV = ModelParams.find_unchanged_devs(ct; rtol = 0.02);
        println("Unchanged deviations: $pNameV")
        @test isa(pNameV, typeof(paramNameV))
        @test length(pNameV) >= 1
	end
end

@testset "Change Table" begin
    change_table_test()
end

# --------------