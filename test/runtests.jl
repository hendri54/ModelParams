using ModelParams
using ModelObjectsLH, Random, Test

mdl = ModelParams;

include("model_test_setup.jl")

@testset "ModelParams" begin
    include("param_table_test.jl");
    include("transformations_test.jl")
    include("parameters_test.jl")
    include("param_vector_test.jl");
    include("pvector_collection_test.jl");
    include("increasing_vector_test.jl")
    include("bounded_increasing_vector_test.jl");
    include("calibrated_array_test.jl");
    include("guess_test.jl");
    include("m_objects_test.jl");
    include("model_test.jl");
end


# -------------
