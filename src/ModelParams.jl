"""
    ModelParams

Support for calibrating models.

A `ModelObject` contains a `ParamVector` and the corresponding parameters. It is key to always keep those in sync.

Change:
    Reporting parameters
        make a "tree" of the model structure +++
            each node has name, type, pvec, children
            then one can re-engineer everything else from this (pvectors, child objects, etc)
"""
module ModelParams

import Base.show, Base.isempty, Base.isequal
import Base.append!, Base.length, Base.getindex

using ArgCheck, DocStringExtensions, Formatting, Parameters, PrettyTables, Printf
using EconometricsLH

# Model objects
export ModelObject
export collect_model_objects, collect_pvectors, find_object, make_guess, validate
# Deviations
export AbstractDeviation, ScalarDeviation, Deviation, RegressionDeviation
export get_data_values, get_unpacked_data_values, get_model_values, get_unpacked_model_values, get_weights
export set_model_values, set_weights!
export scalar_dev, short_display, show_deviation
# Deviation vectors
export DevVector, append!, length, retrieve, scalar_deviation, scalar_devs, show
# Transformations
export LinearTransformation, transform_bounds, transform_param, untransform_param

# ParamVector
export ParamVector
export param_exists, make_dict, make_vector
export param_value, retrieve, vector_to_dict



const ValueType = Float64

"""
    ModelObject

Abstract model object
Must have field `objId :: ObjectId` that uniquely identifies it
May contain a ParamVector, but need not.

Child objects may be vectors. Then the vector must have a fixed element type that is
a subtype of `ModelObject`
"""
abstract type ModelObject end

include("types.jl")
# General purpose code copied from `CommonLH`
include("helpers.jl")
include("object_id.jl")
include("transformations.jl")
include("parameters.jl")
include("param_vector.jl")
include("deviation.jl")
include("devvector.jl")
include("m_objects.jl")


## ------------  Main user interface functions

"""
    make_guess(m :: ModelObject)

Make vector of parameters and bounds for an object
Including nested objects
"""
function make_guess(m :: ModelObject)
    pvecV = collect_pvectors(m);
    guessV, lbV, ubV = make_vector(pvecV, true);
    return guessV :: Vector{Float64}, lbV :: Vector{Float64}, ubV :: Vector{Float64}
end


"""
	$(SIGNATURES)

Perturb guesses at indices `dIdx` by amount `dGuess`.
Ensure that guesses stay in bounds.
"""
function perturb_guess(m :: ModelObject, guessV :: Vector, dIdx, dGuess :: Float64)
    _, lbV, ubV = make_guess(m);
    guess2V = copy(guessV);
    guess2V[dIdx] = guessV[dIdx] .+ dGuess;
    guess2V = min.(max.(guess2V, lbV .+ 0.0001),  ubV .- 0.0001);
    return guess2V
end



"""
    $(SIGNATURES)

Make vector of guesses into model parameters. For object and children.
This changes the values in `m` and in its `pvector`.
"""
function set_params_from_guess!(m :: ModelObject, guessV :: Vector{Float64})
    # Copy guesses into model objects
    # pvecV = collect_pvectors(m);
    objV = collect_model_objects(m);
    # Copy param vectors into model
    vOut = sync_from_vector!(objV, guessV);
    # Make sure all parameters have been used up
    @assert isempty(vOut)
    return nothing
end


"""
    report_params(o :: T1, isCalibrated :: Bool)

Report all parameters by calibration status
For all ModelObjects contained in `o`
"""
function report_params(o :: T1, isCalibrated :: Bool) where T1 <: ModelObject
    # objV, nameV = collect_model_objects(o, :self);
    pvecV = collect_pvectors(o);

    dataM = nothing;
    for pvec in pvecV
        tbM = param_table(pvec, isCalibrated);
        if !isnothing(tbM)
            objId = make_string(pvec.objId);
            if isnothing(dataM)
                dataM = [objId  ""  ""];
            else
                dataM = vcat(dataM, [objId   ""  ""])
            end
            dataM = vcat(dataM, tbM);
        end
    end
    if !isnothing(dataM)
        pretty_table(dataM, noheader = true);
    end
    return nothing
end


"""
    n_calibrated_params(o, isCalibrated)

Number of calibrated parameters in object and its children.
"""
function n_calibrated_params(o :: T1, isCalibrated :: Bool) where T1 <: ModelObject
    pvecV = collect_pvectors(o);
    nParam = 0;
    nElem = 0;
    for i1 = 1 : length(pvecV)
        nParam2, nElem2 = n_calibrated_params(pvecV[i1], isCalibrated);
        nParam += nParam2;
        nElem += nElem2;
    end
    return nParam, nElem
end




"""
    merge_object_arrays!

Merge all arrays (and vectors) from one object into the corresponding arrays
in another object (at given index values)
If target does not have corresponding field: behavior is governed by `skipMissingFields`
"""
function merge_object_arrays!(oSource, oTg, idxV,
    skipMissingFields :: Bool; dbg :: Bool = false)

    nameV = fieldnames(typeof(oSource));
    for name in nameV
        xSrc = getfield(oSource, name);
        if isa(xSrc,  Array)
            # Does target have this field?
            if isdefined(oTg, name)
                xTg = getfield(oTg, name);
                if dbg
                    @assert size(xSrc)[1] == length(idxV)
                    @assert size(xSrc)[2:end] == size(xTg)[2:end] "Size mismatch: $(size(xSrc)) vs $(size(xTg))"
                end
                # For multidimensional arrays (we don't know the dimensions!)
                # we need to loop over "rows"
                for (i1, idx) in enumerate(idxV)
                    # This selects target "row" `idx`
                    tgView = selectdim(xTg, 1, idx);
                    # Copy source "row" `i1` into target row (in place, hence [:])
                    tgView[:] = selectdim(xSrc, 1, i1);
                end
            elseif !skipMissingFields
                error("Missing field $name in target object")
            end
        end
    end
    return nothing
end


end # module
