using CommonLH: ObjectId, ModelObject, ModelSwitches, SingleId, make_object_id, make_child_id, own_name, make_string, ObjIdSeparator, get_object_id, is_model_object, collect_model_objects, collect_model_objects_for_any, collect_object_ids, get_child_objects, find_object, find_only_object, get_value, object_structure, show_object_structure, has_index, make_single_id, n_parents, description
using ModelParams, Test;
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