using ModelParams
using Random, Test

include("object_id_test.jl")
include("parameters_test.jl")
include("deviation_test.jl")
include("model_test.jl")
include("merge_test.jl")


@testset "ModelParams" begin
    println("Testing ModelParams")
    @test param_test()
    include("param_vector_test.jl")
    include("transformations_test.jl")
    model_test()
    set_values_test()
    deviation_test()
    scalar_dev_test()
    regression_dev_test()
    dev_vector_test()

    @test merge_object_arrays_test()
end


# -------------
