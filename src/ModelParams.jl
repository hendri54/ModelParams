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
using ArgCheck, DataStructures, DocStringExtensions, Formatting, Infiltrator, Lazy, Parameters, PrettyTables
using ModelObjectsLH
using EconometricsLH # : RegressionTable, get_all_coeff_se, get_coeff_se_multiple, have_same_regressors


# Transformations
export LinearTransformation, transform_bounds, transform_param, untransform_param

# Parameters
export Param
export calibrate!, fix!, fix_values!, set_bounds!, set_value!, set_default_value!, update!, validate, value, is_calibrated

# ParamVector
export ParamVector
export param_exists, make_dict, n_calibrated_params
export param_table, param_value, param_default_value, report_params, retrieve

# PVectorCollection
export PVectorCollection, set_calibration_status_all_params!, set_default_values_all_params!

# Model objects
export check_fixed_params, check_calibrated_params, check_own_fixed_params, check_own_calibrated_params, validate_all_params
export collect_pvectors, compare_params, check_params_match
export find_pvector, find_param, make_guess, perturb_guess_vector, perturb_params, params_equal, validate
export has_pvector, get_pvector, get_switches, param_tables, latex_param_table
export set_values_from_dicts!, sync_own_values!, sync_values!
export BoundedVector, IncreasingVector, values, set_pvector!

# ParamTable
export ParamTable, get_symbol, get_description, get_values, set_row!, latex_param_table


const ValueType = Float64;
# Bounds for parameter transformations into guess vectors.
const TransformationLb = 1;
const TransformationUb = 2;

include("param_table.jl");
include("types.jl");
# General purpose code copied from `CommonLH`
include("helpers.jl");
include("value_vector.jl");
include("guess.jl");

# Parameters
include("bounded_vector.jl");
include("transformations.jl");
include("parameters.jl");
include("param_vector.jl");

include("m_objects.jl");
include("obj_pvectors.jl");


## ------------  Main user interface functions



"""
	$(SIGNATURES)

Perturb guesses at indices `dIdx` by amount `dGuess`.
Ensure that guesses stay in bounds.
The user typically calls the method that accepts a `ValueVector` instead.
"""
function perturb_guess_vector(m :: ModelObject, g :: Guess{F1},
    guessV :: AbstractVector{F1}, dGuess; dIdx = nothing) where F1

    # vv = make_guess(m);
    if isnothing(dIdx)
        guess2V = guessV .+ dGuess;
    else
        guess2V = copy(guessV);
        guess2V[dIdx] = guessV[dIdx] .+ dGuess;
    end
    enforce_bounds!(m, g, guess2V);
    return guess2V
end

function enforce_bounds!(m :: ModelObject, g :: Guess{F1}, 
    guessV :: AbstractVector{F1}) where F1
    pvecV = collect_pvectors(m);

    for (_, pvec) in pvecV
        enforce_bounds!(pvec, g, guessV);
    end
end

function enforce_bounds!(pvec :: ParamVector, g :: Guess{F1}, guessV :: AbstractVector{F1}) where F1
    for (j, v) in enumerate(guessV)
        if v < lb(pvec.pTransform)
            guessV[j] = lb(pvec.pTransform);
        end
        if v > ub(pvec.pTransform)
            guessV[j] = ub(pvec.pTransform);
        end
    end
end


# """
# 	$(SIGNATURES)

# Perturb a guess, provided as a `ValueVector`. Return a new `ValueVector`.
# """
# function perturb_guess(m :: ModelObject, guess :: ValueVector, dGuess;
#     dIdx = nothing)

#     guessV = perturb_guess(m, get_values(guess), dGuess; dIdx = dIdx);
#     return ValueVector(guessV, lb(guess), ub(guess), pnames(guess))
# end


"""
	$(SIGNATURES)

Perturb calibrated model parameters. Including child objects.
"""
function perturb_params(m :: ModelObject, g :: Guess{F1}, dGuess; dIdx = nothing) where F1
    guessV = get_values(m, g);
    guess2V = perturb_guess_vector(m, g, guessV, dGuess; dIdx = dIdx);
    set_params_from_guess!(m, g, guess2V);
    return nothing
end




"""
    $(SIGNATURES)

Report all parameters by calibration status. For all ModelObjects contained in `o`.

Intended for reporting at the end (or during) a calibration run. Not formatted for inclusion in papers.

Each table row looks like:
"Description (name): value"
"""
function report_params(o :: ModelObject, isCalibrated :: Bool; 
    io :: IO = stdout,
    closeToBounds :: Bool = false)

    # One model object + children at a time. So it can be skipped if no entries.
    mV = collect_model_objects(o; flatten = false);
    for m in mV
        lineV = report_params_one(m, isCalibrated;  closeToBounds);
        if length(lineV) > 1
            for line in lineV
                println(io, line);
            end
        end
    end
end

# This is for a Vector, such as [o2, o2.child1, o2.child2, o2.child2.gc1]
function report_params_one(mV :: Vector{T}, isCalibrated; closeToBounds) where T
    lineV = Vector{String}();
    for (j, m) in enumerate(mV)
        mLineV = report_params_one(m, isCalibrated; closeToBounds);
        # First object Id is always reported, so structure is visible.
        if !isempty(mLineV)  ||  (j == 1)
            push!(lineV, report_obj_id(get_object_id(m)));
        end
        if !isempty(mLineV)
            append!(lineV, mLineV);
        end
    end
    return lineV
end

function report_params_one(m, isCalibrated; closeToBounds)
    if has_pvector(m)
        pvec = get_pvector(m);
        lineV = report_pvec_params(pvec, isCalibrated; closeToBounds);
    else
        lineV = Vector{String}();
    end
    return lineV
end

# Return empty if no matching parameters found.
function report_pvec_params(pvec :: ParamVector, isCalibrated; closeToBounds)
    oId = get_object_id(pvec);
    nParents = n_parents(oId);
    lineV = Vector{String}();
    tbM = param_table(pvec, isCalibrated;  closeToBounds);
    if !isnothing(tbM)
        for ir = 1 : length(tbM)
            push!(lineV, 
                indent_string(nParents + 1) * 
                get_description(tbM, ir) *
                " (" * get_name(tbM, ir) * "):  " *
                get_value(tbM, ir));
        end
    end
    return lineV
end


indent_string(n) = "   " ^ n;

# Report ObjectId with indent depending on no of parents
function report_obj_id(oId :: ObjectId; nParents = n_parents(oId))
    if isempty(description(oId))
        descrStr = "";
    else
        descrStr = ":  " * description(oId);
    end
    return indent_string(nParents) * string(own_name(oId)) * descrStr;
end


"""
	$(SIGNATURES)

Generate a set of `ParamTable`s. One table per model object.
These are stored in a Dict with ObjectId's as keys.

The purpose is to make it easy to generate nicely formatted parameter tables that are grouped in a sensible way.
"""
function param_tables(o :: ModelObject, isCalibrated :: Bool)
    d = Dict{ObjectId, ParamTable}();

    # Iterating over ModelObjects rather than ParamVectors allows specific objects to override how their parameters are reported.
    objV = collect_model_objects(o);
    for obj in objV
        pt = param_table(obj, isCalibrated);
        if !isnothing(pt)
            d[get_object_id(obj)] = pt;
        end
    end
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

# Arguments
- warnWhenMissing: Warn when an `ObjectId` does not have a parameter table (no own calibrated parameters). Default: `false`.
"""
function latex_param_table(o :: ModelObject, isCalibrated :: Bool,
    objIdV :: AbstractVector{ObjectId}, descrV :: AbstractVector{String};
    warnWhenMissing :: Bool = false)

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
        elseif warnWhenMissing
            @warn "$objId not found in $o"
        end
    end
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
    $(SIGNATURES)

Number of calibrated parameters in object and its children. Also returns the number of elements (scalar values) in these parameters.
"""
function n_calibrated_params(o :: T1, isCalibrated :: Bool) where T1 <: ModelObject
    pvecV = collect_pvectors(o);
    nParam = 0;
    nElem = 0;
    if !isempty(pvecV)
        for (_, pvec) in pvecV
            nParam2, nElem2 = n_calibrated_params(pvec, isCalibrated);
            nParam += nParam2;
            nElem += nElem2;
        end
    end
    return nParam, nElem
end


end # module
