function empty_regression_deviation()
    return RegressionDeviation(name = :empty)
end


"""
	$(SIGNATURES)

Returns vector of names, coefficients and std errors
"""
function get_unpacked_data_values(d :: RegressionDeviation)
    dataRt = get_data_values(d);
    return get_all_coeff_se(dataRt)
end


# Return coefficients and std errors in same order as for data
function get_unpacked_model_values(d :: RegressionDeviation)
    nameV = get_names(d.dataV);
    coeffV, seV = get_coeff_se_multiple(d.modelV, nameV);
    return nameV, coeffV, seV
end


"""
	$(SIGNATURES)

Set model values for a RegressionDeviation.

If model regression is missing regressors, the option of setting these regressors to 0 is provided (e.g. for dummies without occurrences).
"""
function set_model_values(d :: RegressionDeviation, modelV :: RegressionTable);
    # setMissingRegressors :: Bool = false)

    # if setMissingRegressors
    #     set_missing_regressors!(modelV, get_names(d.dataV));
    # end

    if !have_same_regressors([d.dataV, modelV])  
        rModelV = get_names(modelV);
        rDataV = get_names(d.dataV);
        error("""Regressors do not match
            $rModelV
            $rDataV""")
    end
    d.modelV = modelV;
    return nothing
end


function get_weights(d :: RegressionDeviation)
    return 1.0
end


# For RegressionDeviation: sum of (model - data) / se
# se2coeffLb governs the scaling of the std errors. s.e./beta >= se2coeffLb
function scalar_dev(d :: RegressionDeviation; se2coeffLb :: Float64 = 0.1,
    inclScalarWt :: Bool = true)
    nameV, coeffV, seV = get_unpacked_data_values(d);
    mNameV, mCoeffV, _ = get_unpacked_model_values(d);
    @assert isequal(nameV, mNameV);

    seV = max.(seV, se2coeffLb .* abs.(coeffV));
    devV = abs.(coeffV - mCoeffV) ./ seV;

    scalarDev = sum(devV);
    if inclScalarWt
        scalarDev *= d.scalarWt;
    end
    scalarStr = sprintf1(d.fmtStr, scalarDev);
    return scalarDev, scalarStr
end


"""
	regression_show_fct

Show a RegressionDeviation
"""
function regression_show_fct(d :: RegressionDeviation; 
    showModel :: Bool = true, fPath :: String = "")

    nameV, coeffV, seV = get_unpacked_data_values(d);
    dataM = hcat(nameV, round.(coeffV, digits = 3), round.(seV, digits = 3));
    headerV = ["Regressor", "Data", "s.e."];

    if showModel
        _, mCoeffV, mSeV = get_unpacked_model_values(d);
        dataM = hcat(dataM,  round.(mCoeffV, digits = 3), round.(mSeV, digits = 3));
        headerV = vcat(headerV, ["Model", "s.e."])
    end

    io = open_show_path(d, fPath = fPath);
    pretty_table(io, dataM,  headerV);
    close_show_path(d, io);
end





# -----------------