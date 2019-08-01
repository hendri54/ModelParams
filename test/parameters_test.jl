"""
## Parameter
"""
function param_test()
    pValue = [1.1 2.2; 3.3 4.4]

    # Simple constructor
    p1 = Param(:p1, "param1", "\$p_{1}\$", pValue);
    @test p1.value == pValue
    @test size(p1.lb) == size(pValue)
    calibrate!(p1)
    @test p1.isCalibrated == true
    fix!(p1)
    @test p1.isCalibrated == false
    validate(p1)

    # Full constructor
    pValue2 = 1.23
    lb2 = -2.8
    ub2 = 7.3
    p2 = Param(:p2, "param2", "\$p_{2}\$", pValue2, pValue2 + 0.5,
        lb2, ub2, true)
    @test p2.value == pValue2
    @test size(p2.ub) == size(pValue2)
    newValue = 9.27
    set_value!(p2, newValue)
    @test p2.value ≈ newValue
    str1 = ModelParams.short_string(p2)
    @test str1 == "p2: 9.27"

    update!(p2, value = 98.2)
    @test p2.value == 98.2
    @test p2.lb == lb2
    update!(p2, lb = -2.0, ub = 8.0)
    @test p2.lb == -2.0
    @test p2.value == 98.2
    validate(p2)

    return true
end
