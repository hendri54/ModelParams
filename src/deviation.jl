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

import Base.show, Base.isempty, Base.length, Base.getindex
export AbstractDeviation, Deviation, scalar_dev, short_display
export DevVector, append!, length, retrieve, scalar_devs, show

# Numeric values are stored as this type
const DevType = Float64

## -----------  Types

abstract type AbstractDeviation end

function isempty(d :: AbstractDeviation)
    return d.name == :empty
end


"""
    Deviation

Holds numeric arrays. The default for deviations.
"""
mutable struct Deviation <: AbstractDeviation
    name  :: Symbol     # eg 'fracEnterIq'
    modelV  :: Array{DevType}   # model values
    dataV  :: Array{DevType}    # data values
    # relative weights, sum to user choice
    wtV  :: Array{DevType}
    # scaleFactor  :: T2    # multiply model and data by this when constructing scalarDev
    shortStr  :: String       # eg 'enter/iq'
    longStr  :: String   # eg 'fraction entering college by iq quartile'
    # For displaying the deviation. Compatible with `Formatting.sprintf1`
    # E.g. "%.2f"
    fmtStr  :: String
end


"""
	ScalarDeviation
"""
mutable struct ScalarDeviation <: AbstractDeviation
    name  :: Symbol     # eg 'fracEnterIq'
    modelV  :: DevType   # model values
    dataV  :: DevType    # data values
    # relative weights, sum to user choice
    wtV  :: DevType
    # scaleFactor  :: T2    # multiply model and data by this when constructing scalarDev
    shortStr  :: String       # eg 'enter/iq'
    longStr  :: String   # eg 'fraction entering college by iq quartile'
    # For displaying the deviation. Compatible with `Formatting.sprintf1`
    # E.g. "%.2f"
    fmtStr  :: String
end


"""
    DevVector

Deviation vector
"""
mutable struct DevVector
    dv :: Vector{AbstractDeviation}
end


## -----------  Deviation struct

"""
    Deviation()

Empty deviation. Mainly as return object when no match is found in DevVector
"""
function Deviation()
    return Deviation(:empty, [0.0], [0.0], [0.0], "", "", "")
end

function ScalarDeviation()
    return Deviation(:empty, 0.0, 0.0, 0.0, "", "", "")
end


"""
	set_model_values

Set model values in an existing deviation
"""
function set_model_values(d :: AbstractDeviation, modelV)
    @assert typeof(modelV) == typeof(d.dataV)  "Type mismatch: $(typeof(modelV)) vs $(typeof(d.dataV))"
    @assert size(modelV) == size(d.dataV)  "Size mismatch: $(size(modelV)) vs $(size(d.dataV))"
    d.modelV = modelV;
    return nothing
end


"""
	set_weights
"""
function set_weights!(d :: AbstractDeviation, wtV)
    @assert typeof(wtV) == typeof(d.dataV)
    @assert size(wtV) == size(d.dataV)
    d.wtV = wtV;
    return nothing
end


"""
    scalar_dev

Scalar deviation from one Deviation object
Scaled to produce essentially an average deviation.
That is: if all deviations in a vector are 0.1, then `scalar_dev = 0.1`
"""
function scalar_dev(d :: Deviation)
    @assert size(d.modelV) == size(d.dataV)

    devV = d.wtV ./ sum(d.wtV) .* ((d.modelV .- d.dataV) .^ 2);
    scalarDev = sum(devV) .^ 0.5;
    scalarStr = sprintf1(d.fmtStr, scalarDev);

    return scalarDev :: DevType, scalarStr
end

function scalar_dev(d :: ScalarDeviation)
    scalarDev = abs(d.modelV - d.dataV);
    scalarStr = sprintf1(d.fmtStr, scalarDev);
    return scalarDev, scalarStr
end


## Formatted short deviation for display
function short_display(d :: AbstractDeviation)
   _, scalarStr = scalar_dev(d);
   return d.shortStr * ": " * scalarStr;
end


## -----------------  Deviation vector

"""
    DevVector()

Constructs an empty deviation vector
"""
function DevVector()
    DevVector(Vector{AbstractDeviation}())
end


"""
    length(d :: DevVector)
"""
function length(d :: DevVector)
    return Base.length(d.dv)
end


"""
    append!(d :: DevVector, dev :: Deviation)

Append a deviation.
"""
function append!(d :: DevVector, dev :: AbstractDeviation)
    @assert !dev_exists(d, dev.name)  "Deviation $(dev.name) already exists"
    Base.push!(d.dv, dev)
end


"""
	set_model_values
"""
function set_model_values(d :: DevVector, name :: Symbol, modelV)
    dev = retrieve(d, name);
    @assert !isempty(dev)
    set_model_values(dev, modelV);
    return nothing
end


"""
	set_weights!
"""
function set_weights!(d :: DevVector, name :: Symbol, wtV)
    dev = retrieve(d, name);
    @assert !isempty(dev)
    set_weights!(dev, wtV);
    return nothing
end


"""
	getindex(d :: DevVector, j)
"""
function getindex(d :: DevVector, j)
    return d.dv[j]
end


"""
    retrieve

If not found: return empty Deviation
"""
function retrieve(d :: DevVector, dName :: Symbol)
    outDev = Deviation();

    n = length(d);
    if n > 0
        dIdx = 0;
        for i1 in 1 : n
            #println("$i1: $(d.dv[i1].name)")
            if d.dv[i1].name == dName
                dIdx = i1;
                break;
            end
            #println("  not found")
        end
        if dIdx > 0
            outDev = d.dv[dIdx];
        end
    end
    return outDev :: Deviation
end


function dev_exists(d :: DevVector, dName :: Symbol)
    return !isempty(retrieve(d, dName))
end


"""
	show

Show all deviations. Each gets a short display with name and scalar deviation.
"""
function show(d :: DevVector)
    if length(d) < 1
        println("No deviations");
    else
        lineV = Vector{String}();
        for i1 in 1 : length(d)
            dStr = short_display(d.dv[i1]);
            push!(lineV, dStr);
        end
    end
    show_string_vector(lineV, 80);
end


"""
	scalar_devs

Return vector of scalar deviations
"""
function scalar_devs(d :: DevVector)
    n = length(d);
    if n > 0
        devV = Vector{DevType}(undef, n);
        for i1 in 1 : n
            dev,_ = scalar_dev(d.dv[i1]);
            devV[i1] = dev;
        end
    else
        devV = Vector{DevType}();
    end
    return devV
end

# -------------
