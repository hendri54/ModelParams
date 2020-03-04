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
    # Indices such that `modelV[idxV...]` matches `dataV`
    # Default is to use all
    idxV :: Vector{Any} = []
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
    # Used when a std error of the data moment is known
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


## -----------  General functions

name(d :: AbstractDeviation) = d.name;

"""
	get_data_values(d :: AbstractDeviation)

Retrieve data values
"""
function get_data_values(d :: AbstractDeviation)
    return d.dataV
end


"""
    $(SIGNATURES)

Retrieve model values
"""
function get_model_values(d :: AbstractDeviation)
    return d.modelV
end


"""
	set_model_values

Set model values in an existing deviation.
"""
function set_model_values(d :: AbstractDeviation, modelV)
    dataV = get_model_values(d);
    if typeof(modelV) != typeof(dataV)  
        println(modelV);
        println(dataV);
        error("Type mismatch in $(d.name): $(typeof(modelV)) vs $(typeof(dataV))");
    end
    @assert size(modelV) == size(dataV)  "Size mismatch: $(size(modelV)) vs $(size(dataV))"
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

"""
    set_weights
    
Does nothing for Deviation types that do not have weights.
"""
function set_weights!(d :: AbstractDeviation, wtV)
    if isa(d, Deviation)
        @assert typeof(wtV) == typeof(get_data_values(d))
        @assert size(wtV) == size(get_data_values(d))
        @assert all(wtV .> 0.0)
        d.wtV = wtV;
    end
    return nothing
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