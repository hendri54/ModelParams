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
import Base.append!, Base.length, Base.getindex, Base.values
import Random: AbstractRNG
using ArgCheck, DocStringExtensions, Formatting, Parameters, PrettyTables
using ModelObjectsLH
using EconometricsLH # : RegressionTable, get_all_coeff_se, get_coeff_se_multiple, have_same_regressors

# SingleId
# export SingleId, make_single_id

# ObjectId
# export ObjectId, make_string, make_object_id, make_child_id, own_name

# Transformations
export LinearTransformation, transform_bounds, transform_param, untransform_param

# Parameters
export Param
export calibrate!, fix!, fix_values!, set_value!, set_default_value!, update!, validate, value

# ParamVector
export ParamVector
export param_exists, make_dict, make_vector
export param_table, param_value, report_params, retrieve, vector_to_dict

# Model objects
# export ModelObject
export check_fixed_params, check_calibrated_params, collect_pvectors, find_pvector, make_guess, perturb_guess, perturb_params, params_equal, validate
export has_pvector, get_pvector, param_tables, latex_param_table
export set_values_from_dicts!
export BoundedVector, IncreasingVector, values, set_pvector!

# Deviations
export AbstractDeviation, ScalarDeviation, Deviation, RegressionDeviation, BoundsDeviation, PenaltyDeviation
export get_data_values, get_unpacked_data_values, get_model_values, get_unpacked_model_values, get_weights, get_std_errors
export set_model_values, set_weights!
export scalar_dev, scalar_devs, scalar_dev_dict, short_display, show_deviation, validate_deviation, long_description, short_description
# Deviation vectors
export DevVector, append!, length, retrieve, scalar_deviation, scalar_devs, show_deviations

# ValueVector
export ValueVector, set_values, values, lb, ub

# ChangeTable
export ChangeTable, set_param_values!, show_table


const ValueType = Float64;

include("param_table.jl");
include("types.jl")
# General purpose code copied from `CommonLH`
include("helpers.jl")

# include("single_id.jl")
# include("object_id.jl")

# Parameters
include("bounded_vector.jl")
include("value_vector.jl")
include("transformations.jl")
include("parameters.jl")
include("param_vector.jl")

# Deviations
include("deviation.jl")
include("regression_deviation.jl")
include("scalar_deviation.jl")
include("matrix_deviation.jl")
include("bounds_deviation.jl")
include("penalty_deviation.jl")
include("devvector.jl")

include("change_table.jl")
include("m_objects.jl")
include("obj_pvectors.jl")


## ------------  Main user interface functions

"""
    $(SIGNATURES)

Make vector of parameters and bounds for an object
Including nested objects
"""
function make_guess(m :: ModelObject)
    pvecV = collect_pvectors(m);
    @assert !isempty(pvecV)  "$m contains no ParamVectors"
    vv = make_vector(pvecV, true);
    return vv :: ValueVector
end


"""
	$(SIGNATURES)

Perturb guesses at indices `dIdx` by amount `dGuess`.
Ensure that guesses stay in bounds.
The user typically calls the method that accepts a `ValueVector` instead.
"""
function perturb_guess(m :: ModelObject, guessV :: Vector, dGuess; dIdx = nothing)
    vv = make_guess(m);
    if isnothing(dIdx)
        guess2V = guessV .+ dGuess;
    else
        guess2V = copy(guessV);
        guess2V[dIdx] = guessV[dIdx] .+ dGuess;
    end
    guess2V = min.(max.(guess2V, lb(vv) .+ 0.0001),  ub(vv) .- 0.0001);
    return guess2V
end

"""
	$(SIGNATURES)

Perturb a guess, provided as a `ValueVector`. Return a new `ValueVector`.
"""
function perturb_guess(m :: ModelObject, guess :: ValueVector, dGuess;
    dIdx = nothing)

    guessV = perturb_guess(m, values(guess), dGuess; dIdx = dIdx);
    return ValueVector(guessV, lb(guess), ub(guess), pnames(guess))
end


"""
	$(SIGNATURES)

Perturb calibrated model parameters. Including child objects.
"""
function perturb_params(m :: ModelObject, dGuess; dIdx = nothing)
    guess = make_guess(m);
    guess2 = perturb_guess(m, guess, dGuess; dIdx = dIdx);
    set_params_from_guess!(m, guess2);
    return nothing
end


"""
    $(SIGNATURES)

Make vector of guesses into model parameters. For object and children.
This changes the values in `m` and in its `pvector`.
"""
function set_params_from_guess!(m :: ModelObject, guess :: ValueVector)
    objV = collect_model_objects(m);
    # Copy param vectors into model
    return sync_from_vector!(objV, guess);
end
    


"""
    $(SIGNATURES)

Report all parameters by calibration status. For all ModelObjects contained in `o`.

Intended for reporting at the end (or during) a calibration run. Not formatted for inclusion in papers.

Each table row looks like:
"Description (name): value"
"""
function report_params(o :: ModelObject, isCalibrated :: Bool; io :: IO = stdout,
    closeToBounds :: Bool = false)

    pvecV = collect_pvectors(o);
    if isempty(pvecV)
        return nothing
    end
    for pvec in pvecV
        tbM = param_table(pvec, isCalibrated; closeToBounds = closeToBounds);
        if !isnothing(tbM)
            oId = get_object_id(pvec);
            nParents = n_parents(oId);
            print(io, indent_string(nParents), string(own_name(oId)));
            if isempty(description(oId))
                println(io, " ");
            else
                println(io, ":  ",  description(oId));
            end
            for ir = 1 : length(tbM)
                println(io, indent_string(nParents + 1), 
                    get_description(tbM, ir),  
                    " (",  get_name(tbM, ir), "):  ", 
                    get_value(tbM, ir));
            end
        end
    end
    return nothing
end

indent_string(n) = "   " ^ n;


"""
	$(SIGNATURES)

Generate a set of `ParamTable`s. One table per model object.
These are stored in a Dict with ObjectId's as keys.

The purpose is to make it easy to generate nicely formatted parameter tables that are grouped in a sensible way.
"""
function param_tables(o :: ModelObject, isCalibrated :: Bool)
    d = Dict{ObjectId, ParamTable}();

    # new +++++
    # Iterating over ModelObjects rather than ParamVectors allows specific objects to override how their parameters are reported.
    objV = collect_model_objects(o);
    for obj in objV
        pt = param_table(obj, isCalibrated);
        if !isnothing(pt)
            d[get_object_id(obj)] = pt;
        end
    end

    # pvecV = collect_pvectors(o);
    # if !isempty(pvecV)
    #     for pvec in pvecV
    #         tbM = param_table(pvec, isCalibrated);
    #         d[get_object_id(pvec)] = tbM;
    #     end
    # end
    return d
end

function param_table(o :: ModelObject, isCalibrated :: Bool)
    if has_pvector(o)
        pt = param_table(get_pvector(o), isCalibrated);
    else
        pt = nothing;
    end
    return pt
end


"""
	$(SIGNATURES)

Make a Latex parameter table for a set of model objects identified by their ObjectIds. Not all objects have ParamVectors.

Returns the table body only as a vector of String. Each element is a line in a Latex table. This can be embedded into a 3 column latex table with headers "Symbol & Description & Value".
"""
function latex_param_table(o :: ModelObject, isCalibrated :: Bool,
    objIdV :: AbstractVector{ObjectId}, descrV :: AbstractVector{String})

    @assert size(objIdV) == size(descrV)

    # Param tables for all model objects. Not efficient, but convenient.
    d = param_tables(o, isCalibrated);

    lineV = Vector{String}();
    for (j, objId) ∈ enumerate(objIdV)
        if haskey(d, objId)
            newLineV = latex_param_table(d[objId], descrV[j]);
            if !isnothing(newLineV)
                append!(lineV, newLineV);
            end
        else
            @warn "$objId not found in $o"
        end
    end

    # pvecV = collect_pvectors(o);
    # if !isempty(pvecV)
    #     for (j, objId) ∈ enumerate(objIdV)
    #         _, pv = find_pvector(pvecV, objId);
    #         if !isnothing(pv)
    #             newLineV = latex_param_table(pv, isCalibrated, descrV[j]);
    #             if !isnothing(newLineV)
    #                 append!(lineV, newLineV);
    #             end
    #         end
    #     end
    # end
    return lineV
end


# Latex parameter table for one `ParamVector`.
# `descr` is an optional description that is made into a multicolumn header.
function latex_param_table(pvec :: ParamVector, isCalibrated :: Bool,
    descr)

    tbM = param_table(pvec, isCalibrated);
    if isnothing(tbM)
        return nothing
    end
    return latex_param_table(tbM, descr)
end


"""
    n_calibrated_params(o, isCalibrated)

Number of calibrated parameters in object and its children.
"""
function n_calibrated_params(o :: T1, isCalibrated :: Bool) where T1 <: ModelObject
    pvecV = collect_pvectors(o);
    nParam = 0;
    nElem = 0;
    if !isempty(pvecV)
        for i1 = 1 : length(pvecV)
            nParam2, nElem2 = n_calibrated_params(pvecV[i1], isCalibrated);
            nParam += nParam2;
            nElem += nElem2;
        end
    end
    return nParam, nElem
end


end # module
