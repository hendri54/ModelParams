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

using ArgCheck, DocStringExtensions, Formatting, Parameters, PrettyTables, Printf
using EconometricsLH

# ObjectId
export ObjectId, make_string, make_single_id, make_object_id

# Model objects
export ModelObject
export collect_model_objects, collect_pvectors, find_object, make_guess, perturb_guess, validate
export get_object_id
export has_pvector, get_pvector
export IncreasingVector, values

# Deviations
export AbstractDeviation, ScalarDeviation, Deviation, RegressionDeviation
export get_data_values, get_unpacked_data_values, get_model_values, get_unpacked_model_values, get_weights
export set_model_values, set_weights!
export scalar_dev, scalar_devs, scalar_dev_dict, short_display, show_deviation
# Deviation vectors
export DevVector, append!, length, retrieve, scalar_deviation, scalar_devs, show
# Transformations
export LinearTransformation, transform_bounds, transform_param, untransform_param

# ParamVector
export ParamVector
export param_exists, make_dict, make_vector
export param_value, retrieve, vector_to_dict

# ValueVector
export ValueVector, values, lb, ub



const ValueType = Float64;
const ObjIdSeparator = " > "

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
"""
function perturb_guess(m :: ModelObject, guessV :: Vector, dIdx, dGuess)
    vv = make_guess(m);
    guess2V = copy(guessV);
    guess2V[dIdx] = guessV[dIdx] .+ dGuess;
    guess2V = min.(max.(guess2V, lb(vv) .+ 0.0001),  ub(vv) .- 0.0001);
    return guess2V
end

"""
	$(SIGNATURES)

Perturb a guess, provided as a `ValueVector`. Return a new `ValueVector`.
"""
function perturb_guess(m :: ModelObject, guess :: ValueVector, dIdx, dGuess)
    guessV = perturb_guess(m, values(guess), dIdx, dGuess);
    return ValueVector(guessV, lb(guess), ub(guess))
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

set_params_from_guess!(m :: ModelObject, guess :: ValueVector) = 
    set_params_from_guess!(m, values(guess));


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
