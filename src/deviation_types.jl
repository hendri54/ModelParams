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

    * `stdV`: std errors of data. Defaults to []. Used when showing deviations.
    * `wtV`: weights within a deviation (e.g. 1/std error)
    * `scalarWt`: used by `DevVector` to weight each `scalar_dev`
    * `showFct`: function that takes an `AbstractDeviation` as input and produces a model/data comparison
    * `showPath`: file name where `showFct` files its output. `stdout` is used if empty.
"""
abstract type AbstractDeviation{F1} end

function isempty(d :: AbstractDeviation)
    return d.name == :empty
end



"""
    Deviation

Holds numeric arrays. The default for deviations.

Contains model values, data values, data std deviations (for display only), weights (for constructing scalar deviation).

Can specify that only `modelV[idxV...]` is to be compared with `dataV`.
"""
@with_kw_noshow mutable struct Deviation{F1 <: AbstractFloat} <: 
    AbstractDeviation{F1}

    name  :: Symbol     # eg 'fracEnterIq'
    modelV  :: Array{F1} = zeros(F1, 1)  # model values
    dataV  :: Array{F1} = zeros(F1, 1)   # data values
    stdV :: Array{F1} = zeros(F1, 1)
    # relative weights, sum to user choice
    wtV  :: Array{F1} = ones(F1, size(dataV))
    # Indices such that `modelV[idxV...]` matches `dataV`
    # Default is to use all
    idxV :: Vector{Any} = []
    # Scales the scalar deviation.
    scalarWt :: F1 = one(F1)
    # Using weighted normp. By default: sum of abs deviations.
    normP :: F1 = one(F1)
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
The scalar deviation is always the absolute deviation. For scalars, the exponent in the norm makes no difference.
"""
@with_kw_noshow mutable struct ScalarDeviation{F1 <: AbstractFloat} <: AbstractDeviation{F1}
    name  :: Symbol     # eg 'fracEnterIq'
    modelV  :: F1 = zero(F1)  # model values
    dataV  :: F1 = zero(F1)   # data values
    stdV :: F1 = zero(F1)
    # Used when a std error of the data moment is known
    wtV :: F1 = one(F1)
    scalarWt :: F1 = one(F1)
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
@with_kw_noshow mutable struct RegressionDeviation{F1} <: AbstractDeviation{F1}
    name  :: Symbol   
    modelV  :: RegressionTable = RegressionTable()
    dataV  :: RegressionTable = RegressionTable()
    scalarWt :: F1 = one(F1)
    normP :: F1 = one(F1)
    shortStr  :: String = String(name)      # eg 'enter/iq'
    longStr  :: String = shortStr
    fmtStr  :: String = "%.2f"
    showFct = regression_show_fct
    showPath :: String = ""
end


"""
	$(SIGNATURES)

Bounds deviation. Returns zero scalar deviation until model values get out of bounds.
"""
@with_kw_noshow mutable struct BoundsDeviation{F1 <: AbstractFloat} <: AbstractDeviation{F1}
    name  :: Symbol 
    modelV  :: Array{F1} = zeros(F1, 1)
    # Bounds
    lbV  :: Array{F1} = zeros(F1, 1)
    ubV  :: Array{F1} = ones(F1, 1)
    # relative weights, sum to user choice
    wtV  :: Array{F1} = ones(F1, size(lbV))
    scalarWt :: F1 = one(F1)
    shortStr  :: String = String(name)  
    # eg 'fraction entering college by iq quartile'
    longStr  :: String = shortStr
    # For displaying the deviation. Compatible with `Formatting.sprintf1`
    # E.g. "%.2f"
    fmtStr  :: String = "%.2f"
    showFct = bounds_show_fct
    showPath :: String = ""
end


"""
	$(SIGNATURES)

Penalty deviation. Calls a function on model values to return scalar deviation.
"""
@with_kw_noshow mutable struct PenaltyDeviation{F1 <: AbstractFloat} <: AbstractDeviation{F1}
    name  :: Symbol 
    modelV  :: Array{F1} = zeros(F1, 1)
    scalarDevFct :: Function
    scalarWt :: F1 = one(F1)
    shortStr  :: String = String(name)  
    longStr  :: String = shortStr
    showFct = penalty_show_fct
    showPath :: String = ""
end


# ------------