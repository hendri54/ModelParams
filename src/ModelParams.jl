"""
    ModelParams

Support for calibrating models

Change:
    Reporting parameters
        make a "tree" of the model structure +++
            each node has name, type, pvec, children
            then one can re-engineer everything else from this (pvectors, child objects, etc)
"""
module ModelParams

import Base.show, Base.isempty, Base.isequal
import Base.length, Base.getindex

using DocStringExtensions, Formatting, Parameters, PrettyTables, Printf
using EconometricsLH

# Model objects
export ModelObject
export collect_model_objects, collect_pvectors, validate
# Deviations
export AbstractDeviation, ScalarDeviation, Deviation, RegressionDeviation
export get_data_values, get_model_values, set_model_values
export scalar_dev, short_display, show_deviation
# Deviation vectors
export DevVector, append!, length, retrieve, scalar_devs, show

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

# General purpose code copied from `CommonLH`
include("helpers.jl")
include("object_id.jl")
include("parameters.jl")
include("param_vector.jl")
include("deviation.jl")
include("devvector.jl")


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
    set_params_from_guess!(m :: ModelObject, guessV :: Vector)

Make vector of guesses into model parameters

# Todo: how to deal with guess transformations +++++
"""
function set_params_from_guess!(m :: ModelObject, guessV :: Vector{Float64})
    # Copy guesses into model objects
    pvecV = collect_pvectors(m);
    objV, _ = collect_model_objects(m, :self);
    # Copy param vectors into model
    vOut = sync_from_vector!(objV, pvecV, guessV);
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

    for i1 = 1 : length(pvecV)
        # objType = typeof(objV[i1]);
        # println("----  $(nameV[i1])  of type  $objType")
        report_params(pvecV[i1], isCalibrated);
    end
end


"""
    n_calibrated_params(o, isCalibrated)

Number of calibrated parameters
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


## -------------  Internals


# There is currently nothing to validate
# Code permits objects without ParamVector or child objects
function validate(m :: T1) where T1 <: ModelObject
    # @assert isa(m.hasParamVector, Bool)
    # @assert isa(get_child_objects(m), Vector)
    @assert isdefined(m, :objId)
    return nothing
end


"""
    get_child_objects

Find the child objects inside a model object
"""
function get_child_objects(o :: T1) where T1 <: ModelObject
    childV = Vector{Any}();
    nameV = Vector{Symbol}();
    for pn in propertynames(o)
        obj = getproperty(o, pn);
        if isa(obj, Vector)
            if eltype(obj) <: ModelObject
                append!(childV, obj);
                for i1 = 1 : length(obj)
                    push!(nameV, Symbol("$pn$i1"));
                end
            end
        else
            if typeof(obj) <: ModelObject
                push!(childV, obj);
                push!(nameV, pn);
            end
        end
    end
    return childV :: Vector, nameV
end


## Find the ParamVector
function get_pvector(o :: T1) where T1 <: ModelObject
    found = false;
    pvec = ParamVector(o.objId);

    # Try the default field
    if isdefined(o, :pvec)
        if isa(o.pvec, ParamVector)
            pvec = o.pvec;
            found = true;
        end
    end

    if !found
        for pn = propertynames(o)
            obj = getproperty(o, pn);
            if isa(obj, ParamVector)
                pvec = obj;
                found = true;
                break;
            end
        end
    end
    return pvec :: ParamVector
end


## Does object contain ParamVector
function has_pvector(o :: T1) where T1 <: ModelObject
    return length(get_pvector(o)) > 0
end


"""
    collect_model_objects

Collect all model objects inside an object
Recursive. Also collects objects inside child objects and so on.
"""
function collect_model_objects(o :: T1, objName :: Symbol) where T1 <: ModelObject
    outV = Vector{Any}();
    nameV = Vector{Symbol}();
    if has_pvector(o)
        push!(outV, o);
        push!(nameV, objName);
    end

    # Objects directly contained in `o`
    childObjV, childNameV = get_child_objects(o);
    if !Base.isempty(childObjV)
        for i1 = 1 : length(childObjV)
            nestedObjV, nestedNameV = collect_model_objects(childObjV[i1], childNameV[i1]);
            append!(outV, nestedObjV);
            append!(nameV, nestedNameV);
        end
    end
    return outV :: Vector, nameV :: Vector{Symbol}
end


function collect_pvectors(o :: T1) where T1 <: ModelObject
    objV, _ = collect_model_objects(o, :self);
    pvecV = Vector{ParamVector}();
    for i1 = 1 : length(objV)
        push!(pvecV, get_pvector(objV[i1]));
    end
    return pvecV :: Vector{ParamVector}
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
