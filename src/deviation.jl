#=
Model/data deviations for calibration

Intended workflow:
* Set up deviations while defining model. Load in the data.
* After solving the model: fill in model values.
* Compute deviations for calibration.
* Report deviations.
* Show model fit. (All the last steps can simply work of the deviation vector)

# Todo

* Make an iterator for deviations
=#

# Numeric values are stored as this type
const DevType = Float64

## -----------  Types


"""
	AbstractDeviation

Abstract type for Deviation objects. A Deviation object implements:

    * `set_model_values`
    * `scalar_dev`

Contains:

    * `wtV`: weights within a deviation (e.g. 1/std error)
    * `scalarWt`: used by `DevVector` to weight each `scalar_dev`
    * `showFct`: function that takes an `AbstractDeviation` as input and produces a model/data comparison
    * `showPath`: file name where `showFct` files its output. `stdout` is used if empty.
"""
abstract type AbstractDeviation end

function isempty(d :: AbstractDeviation)
    return d.name == :empty
end



"""
    Deviation

Holds numeric arrays. The default for deviations.

"""
@with_kw mutable struct Deviation <: AbstractDeviation
    name  :: Symbol     # eg 'fracEnterIq'
    modelV  :: Array{DevType} = DevType[0.0]  # model values
    dataV  :: Array{DevType} = DevType[0.0]   # data values
    # relative weights, sum to user choice
    wtV  :: Array{DevType} = ones(DevType, size(dataV))
    scalarWt :: DevType = 1.0
    shortStr  :: String = String(name)      # eg 'enter/iq'
    # eg 'fraction entering college by iq quartile'
    longStr  :: String = shortStr
    # For displaying the deviation. Compatible with `Formatting.sprintf1`
    # E.g. "%.2f"
    fmtStr  :: String = "%.2f"
    showFct = deviation_show_fct
    showPath :: String = ""
end


"""
    ScalarDeviation
    
Here the `wtV` field is intended to hold 1 / std error of the moment.
"""
@with_kw mutable struct ScalarDeviation <: AbstractDeviation
    name  :: Symbol     # eg 'fracEnterIq'
    modelV  :: DevType = DevType(0.0)  # model values
    dataV  :: DevType = DevType(0.0)   # data values
    wtV :: DevType = DevType(1.0)
    scalarWt :: DevType = 1.0
    shortStr  :: String = String(name)      # eg 'enter/iq'
    longStr  :: String = shortStr
    fmtStr  :: String = "%.2f"
    showFct = scalar_show_fct
    showPath :: String = ""
end


"""
	RegressionDeviation

Holds model and data in the form of `RegressionTable` objects
"""
@with_kw mutable struct RegressionDeviation <: AbstractDeviation
    name  :: Symbol   
    modelV  :: RegressionTable = RegressionTable()
    dataV  :: RegressionTable = RegressionTable()
    scalarWt :: DevType = 1.0
    shortStr  :: String = String(name)      # eg 'enter/iq'
    longStr  :: String = shortStr
    fmtStr  :: String = "%.2f"
    showFct = regression_show_fct
    showPath :: String = ""
end


## -----------  Deviation struct

"""
    empty_deviation()

Empty deviation. Mainly as return object when no match is found in DevVector
"""
function empty_deviation()
    return Deviation(name = :empty)
end

function empty_scalar_deviation()
    return ScalarDeviation(name = :empty)
end

function empty_regression_deviation()
    return RegressionDeviation(name = :empty)
end


"""
	get_data_values(d :: AbstractDeviation)

Retrieve data values
"""
function get_data_values(d :: AbstractDeviation)
    return d.dataV
end


"""
	$(SIGNATURES)

Returns vector of names, coefficients and std errors
"""
function get_unpacked_data_values(d :: RegressionDeviation)
    dataRt = get_data_values(d);
    return get_all_coeff_se(dataRt)
end


"""
    $(SIGNATURES)

Retrieve model values
"""
function get_model_values(d :: AbstractDeviation)
    return d.modelV
end

# Return coefficients and std errors in same order as for data
function get_unpacked_model_values(d :: RegressionDeviation)
    nameV = get_names(d.dataV);
    coeffV, seV = get_coeff_se_multiple(d.modelV, nameV);
    return nameV, coeffV, seV
end


"""
	set_model_values

Set model values in an existing deviation.
"""
function set_model_values(d :: AbstractDeviation, modelV)
    if typeof(modelV) != typeof(d.dataV)  
        println(modelV);
        println(d.dataV);
        error("Type mismatch in $(d.name): $(typeof(modelV)) vs $(typeof(d.dataV))");
    end
    @assert size(modelV) == size(d.dataV)  "Size mismatch: $(size(modelV)) vs $(size(d.dataV))"
    d.modelV = modelV;
    return nothing
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


"""
	$(SIGNATURES)

Retrieve weights. Returns scalar 1 for scalar deviations.
"""
function get_weights(d :: AbstractDeviation)
    return d.wtV
end

function get_weights(d :: ScalarDeviation)
    return 1.0
end

function get_weights(d :: RegressionDeviation)
    return 1.0
end


"""
    set_weights
    
Does nothing for Deviation types that do not have weights.
"""
function set_weights!(d :: AbstractDeviation, wtV)
    if isa(d, Deviation)
        @assert typeof(wtV) == typeof(d.dataV)
        @assert size(wtV) == size(d.dataV)
        @assert all(wtV .> 0.0)
        d.wtV = wtV;
    end
    return nothing
end


"""
    $(SIGNATURES)

Scalar deviation from one Deviation object.

Optionally includes `scalarWt` factor.
"""
function scalar_dev(d :: Deviation; inclScalarWt :: Bool = true)
    @assert size(d.modelV) == size(d.dataV)

    devV = d.wtV .* abs.(d.modelV .- d.dataV);
    scalarDev = sum(devV);
    if inclScalarWt
        scalarDev *= d.scalarWt;
    end
    scalarStr = sprintf1(d.fmtStr, scalarDev);

    return scalarDev :: DevType, scalarStr
end

function scalar_dev(d :: ScalarDeviation; inclScalarWt :: Bool = true)
    scalarDev = abs(d.modelV - d.dataV) * d.wtV;
    if inclScalarWt
        scalarDev *= d.scalarWt;
    end
    scalarStr = sprintf1(d.fmtStr, scalarDev);
    return scalarDev, scalarStr
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


## Formatted short deviation for display
function short_display(d :: AbstractDeviation; inclScalarWt :: Bool = true)
   _, scalarStr = scalar_dev(d, inclScalarWt = inclScalarWt);
   return d.shortStr * ": " * scalarStr;
end


## ---------------  Display

"""
    $(SIGNATURES)

Show a deviation using the show function contained in its definition.

Optionally, a file path can be provided. If none is provided, the path inside the deviation is used.
"""
function show_deviation(d :: AbstractDeviation; showModel :: Bool = true, fPath :: String = "")
    return d.showFct(d,  showModel = showModel, fPath = fPath)
end


"""
    $(SIGNATURES)

Show a scalar deviation. Fallback if not user-defined function is provided.
Appends to the provided file (if any).
"""
function scalar_show_fct(d :: ScalarDeviation; showModel :: Bool = true, fPath :: String = "")
    io = open_show_path(d, fPath = fPath, writeMode = "a");
    write(io, scalar_show_string(d) * "\n");
    close_show_path(d, io);
    return nothing
end

function scalar_show_string(d :: ScalarDeviation; showModel :: Bool = true)
    if showModel
        mStr = " m: " * sprintf1(d.fmtStr, d.modelV);
    else
        mStr = "";
    end
    dStr = sprintf1(d.fmtStr, d.dataV)
    return "$(d.name): $mStr  d: $dStr"
end


"""
	$(SIGNATURES)

Show a vector / matrix deviation
"""
function deviation_show_fct(d :: Deviation; showModel :: Bool = true, fPath :: String = "")
    io = open_show_path(d, fPath = fPath);

    # Dimensions of data matrix
    nd = ndims(d.dataV);
    if nd > 2
        @warn "Showing deviation not implemented for ndims = $nd"
    elseif nd == 2
        (nr, nc) = size(d.dataV);
    elseif nd == 1
        nr = length(d.dataV);
        nc = 1;
    else
        error("Empty deviation")
    end

    println(io, "$(d.name):  Model / Data")
    for ir = 1 : nr
        print(io, "\t $ir: ");
        for ic = 1 : nc
            if showModel
                mStr = sprintf1(d.fmtStr, d.modelV[ir, ic]);
            else
                mStr = "  --  ";
            end
            dStr = sprintf1(d.fmtStr, d.dataV[ir, ic]);
            print(io, "\t $mStr / $dStr");
        end
        print(io, "\n");
    end

    close_show_path(d, io);
    return nothing
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


function open_show_path(d :: AbstractDeviation; 
    fPath :: String = "", writeMode :: String = "w")

    if isempty(fPath)
        showPath = d.showPath;
    else
        showPath = fPath;
    end
    if isempty(showPath)
        io = stdout;
    else
        io = open(showPath, "w");
    end
    return io
end

function close_show_path(d :: AbstractDeviation, io)
    if io != stdout
        close(io);
    end
end



# -------------
