using ModelParams, Test

mp = ModelParams;

function param_table_test()
    @testset "ParamTable" begin
        n = 5;
        nameV = ["name$j"  for j = 1 : n];
        symbolV = ["sym$j"  for j = 1 : n];
        descrV = ["descr$j"  for j = 1 : n];
        valueV = ["val$j"  for j = 1 : n];

        pt = ParamTable(n);
        @test length(pt) == n

        for j = 1 : n
            set_row!(pt, j, nameV[j], symbolV[j], descrV[j], valueV[j]);
        end

        for j = 1 : n
            @test mp.get_symbol(pt, j) == symbolV[j]
            @test mp.get_value(pt, j) == valueV[j]
        end

        @test mp.get_descriptions(pt) == descrV

        lineV = latex_param_table(pt, "Description line");
        @test isa(lineV, Vector{String})
        @test length(lineV) == n+1
	end
end

@testset "ParamTable" begin
    param_table_test();
end

# -----------