using CommonLH: ObjectId, ModelObject, ModelSwitches, SingleId, make_object_id, make_child_id, own_name, make_string, ObjIdSeparator, get_object_id, is_model_object, collect_model_objects, collect_model_objects_for_any, collect_object_ids, get_child_objects, find_object, find_only_object, get_value, object_structure, show_object_structure, has_index, make_single_id, n_parents, description
using ModelParams, Test

function make_bounded_test_vector(vLength :: Integer, increasing :: Symbol)
    ownId = ObjectId(:test1);
    lb = 3.0;
    ub = 7.0;
    if increasing == :nonmonotone
        if vLength > 1
            dxV = collect(LinRange(lb + 0.1, ub - 0.1, vLength));
        else
            dxV = [lb + 1.5];
        end
    else
        if vLength > 1
            dxV = collect(range(0.4, 0.2, length = vLength));
        else
            dxV = [0.4];
        end
    end
    iv = BoundedVector(ownId, ParamVector(ownId), increasing, lb, ub, dxV);
    set_pvector!(iv);
    return iv
end


@testset "BoundedVector" begin
    for vLength in [1, 3]
        for increasing in [:increasing, :decreasing, :nonmonotone]
            iv = make_bounded_test_vector(vLength, increasing);
            n = length(iv);
            xV = values(iv);
            @test ModelParams.check_values(iv, xV)

            for j = 1 : n
                @test values(iv, j) == xV[j]
            end

            xNewV = xV .+ 0.05;
    		fix_values!(iv, xNewV);
            x2V = values(iv);
            @test isapprox(xNewV, x2V)
        end
    end
end


# ------------------