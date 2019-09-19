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
"""
@with_kw mutable struct ScalarDeviation <: AbstractDeviation
    name  :: Symbol     # eg 'fracEnterIq'
    modelV  :: DevType = DevType(0.0)  # model values
    dataV  :: DevType = DevType(0.0)   # data values
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
	get_data_values(d :: RegressionDeviation)

Returns vector of names, coefficients and std errors
"""
function get_data_values(d :: RegressionDeviation)
    return get_all_coeff_se(d.dataV)
end


"""
	get_model_values

Retrieve model values
"""
function get_model_values(d :: AbstractDeviation)
    return d.modelV
end

# Return coefficients and std errors in same order as for data
function get_model_values(d :: RegressionDeviation)
    nameV = get_names(d.dataV);
    coeffV, seV = get_coeff_se_multiple(d.modelV, nameV);
    return nameV, coeffV, seV
end


"""
	set_model_values

Set model values in an existing deviation
Does not ensure that order matches between model and data for RegressionDeviation.
"""
function set_model_values(d :: AbstractDeviation, modelV)
    @assert typeof(modelV) == typeof(d.dataV)  "Type mismatch: $(typeof(modelV)) vs $(typeof(d.dataV))"
    @assert size(modelV) == size(d.dataV)  "Size mismatch: $(size(modelV)) vs $(size(d.dataV))"
    d.modelV = modelV;
    return nothing
end

function set_model_values(d :: RegressionDeviation, modelV :: RegressionTable)
    if !have_same_regressors([d.dataV, modelV])  
        rModelV = get_names(modelV);
        rDataV = get_names(d.dataV);
        @warn """Regressors do not match
            $rModelV
            $rDataV"""
        error("Fatal.")
    end
    d.modelV = modelV;
    return nothing
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
    scalar_dev

Scalar deviation from one Deviation object.
"""
function scalar_dev(d :: Deviation)
    @assert size(d.modelV) == size(d.dataV)

    devV = d.wtV .* abs.(d.modelV .- d.dataV);
    scalarDev = sum(devV);
    scalarStr = sprintf1(d.fmtStr, scalarDev);

    return scalarDev :: DevType, scalarStr
end

function scalar_dev(d :: ScalarDeviation)
    scalarDev = abs(d.modelV - d.dataV);
    scalarStr = sprintf1(d.fmtStr, scalarDev);
    return scalarDev, scalarStr
end

# se2coeffLb governs the scaling of the std errors. s.e./beta >= se2coeffLb
function scalar_dev(d :: RegressionDeviation; se2coeffLb :: Float64 = 0.1)
    nameV, coeffV, seV = get_data_values(d);
    mNameV, mCoeffV, _ = get_model_values(d);
    @assert isequal(nameV, mNameV);

    seV = max.(seV, se2coeffLb .* abs.(coeffV));
    devV = abs.(coeffV - mCoeffV) ./ seV;

    scalarDev = sum(devV);
    scalarStr = sprintf1(d.fmtStr, scalarDev);
    return scalarDev, scalarStr
end


## Formatted short deviation for display
function short_display(d :: AbstractDeviation)
   _, scalarStr = scalar_dev(d);
   return d.shortStr * ": " * scalarStr;
end


## ---------------  Display

"""
	show_deviation

Show a deviation using the show function contained in its definition.
"""
function show_deviation(d :: AbstractDeviation)
    return d.showFct(d)
end


"""
	scalar_show_fct

Show a scalar deviation. Fallback if not user-defined function is provided.
Appends to the provided file (if any).
"""
function scalar_show_fct(d :: ScalarDeviation)
    io = open_show_path(d, writeMode = "a");
    write(io, scalar_show_string(d) * "\n");
    close_show_path(d, io);
    return nothing
end

function scalar_show_string(d :: ScalarDeviation)
    mStr = sprintf1(d.fmtStr, d.modelV)
    dStr = sprintf1(d.fmtStr, d.dataV)
    return "$(d.name):  m: $mStr  d: $dStr"
end


"""
	deviation_show_fct

Show a vector / matrix deviation
"""
function deviation_show_fct(d :: Deviation)
    io = open_show_path(d);

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
            mStr = sprintf1(d.fmtStr, d.modelV[ir, ic]);
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
function regression_show_fct(d :: RegressionDeviation)
    nameV, coeffV, seV = get_data_values(d);
    _, mCoeffV, mSeV = get_model_values(d);
    dataM = hcat(nameV, 
        round.(coeffV, digits = 3), round.(seV, digits = 3), 
        round.(mCoeffV, digits = 3), round.(mSeV, digits = 3));

    io = open_show_path(d);
    pretty_table(io, dataM,  ["Regressor", "Data", "s.e.", "Model", "s.e."]);
    close_show_path(d, io);
end


function open_show_path(d :: AbstractDeviation; writeMode :: String = "w")
    if isempty(d.showPath)
        io = stdout;
    else
        io = open(d.showPath, "w");
    end
    return io
end

function close_show_path(d :: AbstractDeviation, io)
    if io != stdout
        close(io);
    end
end



# -------------
