using ModelParamsTest

@testset "ModelParams" begin
    println("Testing ModelParams")
    @test ModelParamsTest.single_id_test()
    @test ModelParamsTest.object_id_test()
    @test ModelParamsTest.param_test()
   	@test ModelParamsTest.pvectorTest()
   	@test ModelParamsTest.get_pvector_test()
   	@test ModelParamsTest.pvectorDictTest()
   	@test ModelParamsTest.report_test()
    @test ModelParamsTest.modelTest()
    @test ModelParamsTest.deviationTest()
    @test ModelParamsTest.devVectorTest()

    @test ModelParamsTest.merge_object_arrays_test()
end
