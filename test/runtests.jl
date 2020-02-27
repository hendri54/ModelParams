using ModelParams
using Random, Test


@testset "ModelParams" begin
    println("Testing ModelParams")
    include("object_id_test.jl")
    include("parameters_test.jl")
    include("param_vector_test.jl")
    include("transformations_test.jl")
    include("model_test.jl")
    include("deviation_test.jl")
    include("increasing_vector_test.jl")
end


# -------------
