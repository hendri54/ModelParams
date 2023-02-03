using ModelObjectsLH, ModelParams, Test;
mdl = ModelParams;

function grouped_v_test()
    @testset "Grouped vector" begin
        ng = 3;
        fixedValV = collect(LinRange(2.0, 5.0, ng));
        groupCalV = [true, false, true];
        catGroupV = [[1,2], [3], [1,3], [2], [1]];
        gv = make_grouped_vector(ObjectId(:test), 
            catGroupV, groupCalV, fixedValV);

        for ig = 1 : ng
            v = mdl.group_value(gv, ig);
            @test -100.0 < v < 100.0;
        end

        for iCat = 1 : length(catGroupV)
            v = pvalue(gv, iCat);
            @test -100.0 < v < 100.0;
        end

        # if not calibrated: check that group value is fixed
        

    end
end


@testset "GroupedVector" begin
    grouped_v_test();
end

# -------------