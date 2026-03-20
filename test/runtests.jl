using ModelParams
using CommonLH: ObjectId, ModelObject, ModelSwitches, SingleId, make_object_id, make_child_id, own_name, make_string, ObjIdSeparator, get_object_id, is_model_object, collect_model_objects, collect_model_objects_for_any, collect_object_ids, get_child_objects, find_object, find_only_object, get_value, object_structure, show_object_structure, has_index, make_single_id, n_parents, description
using Random, Test

mdl = ModelParams;

include("model_test_setup.jl")

@testset "ModelParams" begin
    include("param_table_test.jl");
    include("transformations_test.jl");
    include("parameters_test.jl");
    # include("cal_vector_test.jl");
    include("param_vector_test.jl");
    include("pvector_collection_test.jl");
    include("increasing_vector_test.jl");
    # include("bounded_increasing_vector_test.jl");
    # include("calibrated_array_test.jl");
    include("guess_test.jl");
    include("m_objects_test.jl");
    include("model_test.jl");
end


# -------------
