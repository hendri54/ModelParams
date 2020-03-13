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

using ArgCheck, DocStringExtensions, Formatting, Parameters, PrettyTables
using EconometricsLH

# SingleId
export SingleId, make_single_id

# ObjectId
export ObjectId, make_string, make_object_id

# Transformations
export LinearTransformation, transform_bounds, transform_param, untransform_param

# Parameters
export Param
export calibrate!, fix!, set_value!, update!, validate

# ParamVector
export ParamVector
export param_exists, make_dict, make_vector
export param_value, retrieve, vector_to_dict

# Model objects
export ModelObject
export check_fixed_params, check_calibrated_params, collect_model_objects, collect_pvectors, find_object, make_guess, perturb_guess, perturb_params, params_equal, validate
export get_object_id, has_pvector, get_pvector
export set_values_from_dicts!
export IncreasingVector, values

# Deviations
export AbstractDeviation, ScalarDeviation, Deviation, RegressionDeviation
export get_data_values, get_unpacked_data_values, get_model_values, get_unpacked_model_values, get_weights
export set_model_values, set_weights!
export scalar_dev, scalar_devs, scalar_dev_dict, short_display, show_deviation
# Deviation vectors
export DevVector, append!, length, retrieve, scalar_deviation, scalar_devs, show

# ValueVector
export ValueVector, set_values, values, lb, ub



const ValueType = Float64;
const ObjIdSeparator = " > "


include("types.jl")
# General purpose code copied from `CommonLH`
include("helpers.jl")
include("single_id.jl")
include("object_id.jl")
include("transformations.jl")
include("parameters.jl")
include("param_vector.jl")
include("deviation.jl")
include("regression_deviation.jl")
include("scalar_deviation.jl")
include("matrix_deviation.jl")
include("devvector.jl")
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

Report all parameters by calibration status
For all ModelObjects contained in `o`
"""
function report_params(o :: ModelObject, isCalibrated :: Bool; io :: IO = stdout) 
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
        pretty_table(io, dataM, noheader = true);
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


end # module
