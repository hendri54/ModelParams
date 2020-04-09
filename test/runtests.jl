using ModelParams
using Random, Test


include("deviation_test_setup.jl")
include("model_test_setup.jl")

@testset "ModelParams" begin
    println("Testing ModelParams")
    include("object_id_test.jl")
    include("transformations_test.jl")
    include("parameters_test.jl")
    include("param_vector_test.jl")
    include("m_objects_test.jl")
    include("model_test.jl")
    include("deviation_test.jl")
    include("dev_vector_test.jl")
    include("change_table_test.jl")
    include("increasing_vector_test.jl")
end


# -------------
