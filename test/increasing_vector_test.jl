function make_increasing_vector()
	x0 = -1.0;
	dWageV = [0.1, 3.2];
    wageInter = Param(:x0, "Wage HSG", "wHSG",  
        x0, x0,  x0 .* 0.05, x0 .* 10,  true);
    dWage = Param(:dxV, "Wage gradient", "dw",
        dWageV, dWageV, dWageV .* 0.05, dWageV .* 10, true);

	ownId = ObjectId(:test1);
    # pvec = ParamVector(ownId,  [wageInter, dWage]);
	return IncreasingVector(ownId, wageInter, dWage)
end


# function increasing_vector_test()
	@testset "IncreasingVector" begin
		iv = make_increasing_vector();
		xV = values(iv);
		@test all(diff(xV) .> 0.0)
		@test xV[1] ≈ pvalue(iv.x0)
		@test xV[end] ≈ pvalue(iv.x0) + sum(pvalue(iv.dxV))
	end
# end


# ------------------