using ModelParams
using Random, Test

include("object_id_test.jl")
include("parameters_test.jl")
include("deviation_test.jl")
include("model_test.jl")


@testset "ModelParams" begin
    println("Testing ModelParams")
    param_test()
    include("param_vector_test.jl")
    include("transformations_test.jl")
    model_test()
    set_values_test()
    change_values_test()
    deviation_test()
    scalar_dev_test()
    regression_dev_test()
    dev_vector_test()
end


# -------------
