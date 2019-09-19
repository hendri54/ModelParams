using ModelParams
using Random, Test

include("object_id_test.jl")
include("parameters_test.jl")
include("param_vector_test.jl")
include("deviation_test.jl")
include("model_test.jl")
include("merge_test.jl")


@testset "ModelParams" begin
    println("Testing ModelParams")
    @test param_test()
   	@test pvectorTest()
   	@test get_pvector_test()
   	@test pvectorDictTest()
   	report_test()
    model_test()
    deviation_test()
    scalar_dev_test()
    regression_dev_test()
    dev_vector_test()

    @test merge_object_arrays_test()
end


# -------------
