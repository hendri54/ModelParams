"""
	$(SIGNATURES)

Constructors for ParamVector
"""
function ParamVector(id :: ObjectId)
    return ParamVector(objId = id)
end

# With default parameter transformation
function ParamVector(id :: ObjectId, pv :: Vector)
    return ParamVector(id, pv, LinearTransformation(lb = 1.0, ub = 2.0))
end


function show(io :: IO,  pvec :: ParamVector)
    n = length(pvec);
    idStr = make_string(pvec.objId);
    println(io,  "ParamVector $idStr of length $n");
    if n > 0
        for j = 1 : n
            show(io, pvec[j]);
        end
    end
    return nothing
end

get_object_id(pv :: ParamVector) = pv.objId;
has_object_id(pv :: ParamVector) = true;

"""
    length

Returns number of parameters
"""
function length(pvec :: ParamVector)
    return Base.length(pvec.pv)
end

"""
	$(SIGNATURES)
"""
function isempty(pvec :: ParamVector)
    return Base.isempty(pvec.pv)
end



# Check that param vector matches model object
function check_match(pvec :: ParamVector, objId :: ObjectId)
    return isequal(pvec.objId, objId)
end


## ----------  Retrieve

"""
	$(SIGNATURES)
"""
function getindex(pvec :: ParamVector, j :: Integer)
    @argcheck j <= Base.length(pvec.pv)
    return pvec.pv[j]
end



"""
    retrieve

Returns the index of a named parameter.

First occurrence. Returns 0 if not found.
"""
function retrieve(pvec :: ParamVector, pName :: Symbol)
    idxOut = 0;
    n = length(pvec);
    if n > 0
        for idx = 1 : n
            p = pvec.pv[idx];
            if p.name == pName
                idxOut = idx;
                found = true;
                break
            end
        end
    end
    if idxOut > 0
        p = pvec.pv[idxOut]
        return p, idxOut
    else
        return nothing, 0
    end
end


"""
	$(SIGNATURES)

Does a `Param` named `pName` exist in `ParamVector pvec`?
"""
function param_exists(pvec :: ParamVector, pName :: Symbol)
    _, idx = retrieve(pvec, pName);
    return idx > 0
end


"""
	$(SIGNATURES)

Return the value of a parameter from a `ParamVector`. 
Returns `nothing` if not found.
"""
function param_value(pvec :: ParamVector, pName :: Symbol)
    p, idx = retrieve(pvec, pName);
    if idx > 0
        return p.value;
    else
        return nothing
    end
end


"""
	$(SIGNATURES)

Return indices of all parameters with a given calibration status.
"""
function indices_calibrated(pvec :: ParamVector, isCalibrated :: Bool)
    n = length(pvec);
    if n > 0
        isCalV = [pvec.pv[j].isCalibrated  for j in 1 : n];
        idxV = findall(isCalV .== isCalibrated);
    else
        idxV = Vector{Int}();
    end
    return idxV
end



## ------------  Modify

"""
    append!

Append a `Param` to a `ParamVector`
"""
function append!(pvec :: ParamVector,  p :: Param)
    @assert !param_exists(pvec, p.name)  "$(p.name) already exists"
    push!(pvec.pv, p)
    return nothing
end

function remove!(pvec :: ParamVector, pName :: Symbol)
    _, idx = retrieve(pvec, pName);
    @assert (idx > 0)  "$pName does not exist"
    deleteat!(pvec.pv, idx);
    return nothing
end

function replace!(pvec :: ParamVector, p :: Param)
    remove!(pvec, p.name);
    append!(pvec, p);
    return nothing
end

function change_calibration_status!(pvec :: ParamVector, pName :: Symbol,
    doCal :: Bool)

    _, idx = retrieve(pvec, pName);
    @assert (idx > 0)  "$pName does not exist"
    if doCal
        calibrate!(pvec.pv[idx])
    else
        fix!(pvec.pv[idx])
    end
end

function change_value!(pvec :: ParamVector, pName :: Symbol, newValue)
    _, idx = retrieve(pvec, pName);
    @assert (idx > 0)  "$pName does not exist"
    oldValue = set_value!(pvec.pv[idx], newValue);
    return oldValue
end


"""
    $(SIGNATURES)

Reports calibrated (or fixed) parameters for one ParamVector
"""
function report_params(pvec :: ParamVector, isCalibrated :: Bool;
    io :: IO = stdout)

    objId = make_string(pvec.objId);
    dataM = param_table(pvec, isCalibrated);

    if isnothing(dataM)
        println(io, "\t$objId:  Nothing to report");
    else
        pretty_table(io, dataM, [objId, " ", " "]);
    end
    return nothing
end


"""
	$(SIGNATURES)

Table with calibrated parameters
"""
function param_table(pvec :: ParamVector, isCalibrated :: Bool)
    idxV = indices_calibrated(pvec, isCalibrated);
    n = length(idxV);

    if isempty(idxV)
        dataM = nothing;
    else
        dataM = Matrix{String}(undef, n, 3);
        for j = 1 : n
            p = pvec[idxV[j]];
            dataM[j,2] = string(p.name);
            dataM[j,1] = p.description;
            dataM[j,3] = formatted_value(p.value);
        end
    end
    return dataM
end


"""
    n_calibrated_params

Number of calibrated parameters
"""
function n_calibrated_params(pvec :: ParamVector, isCalibrated :: Bool)
    nParams = 0;
    nElem = 0;
    n = length(pvec);
    if n > 0
        for i1 = 1 : n
            if pvec.pv[i1].isCalibrated == isCalibrated
                nParams += 1;
                nElem += length(pvec.pv[i1].value);
            end
        end
    end
    return nParams, nElem
end


"""
    $(SIGNATURES)

Collect values or default values into Dict.
Used to go back and forth between guess and model parameters.
"""
function make_dict(pvec :: ParamVector, isCalibrated :: Bool,
    useValues :: Bool)

    n = length(pvec);
    if n < 1
        pd = nothing
    else
        pd = Dict{Symbol, Any}()
        for i1 in 1 : n
            p = pvec.pv[i1];
            if p.isCalibrated == isCalibrated
                if useValues
                    pd[p.name] = p.value;
                else
                    pd[p.name] = p.defaultValue;
                end
            end
        end
    end
    return pd
end

# Typically, useValues when calibrated; defaults otherwise
function make_dict(pvec :: ParamVector, isCalibrated :: Bool)
    if isCalibrated
        useValues = true;
    else
        useValues = false;
    end
    return make_dict(pvec, isCalibrated, useValues)
end


"""
    $(SIGNATURES)

Make vector of values, lb, ub for optimization algorithm.

Vectors are transformed using the `ParameterTransformation` specified in the `ParamVector`.
"""
function make_vector(pvec :: ParamVector, isCalibrated :: Bool)
    T1 = ValueType;
    valueV = Vector{T1}();

    n = length(pvec);
    if n > 0
        for i1 in 1 : n
            p = pvec.pv[i1];
            if p.isCalibrated == isCalibrated
                pValue = transform_param(pvec.pTransform,  p);
                # Append works for scalars, vectors, and matrices (that get flattened)
                # Need to qualify - otherwise local append! is called
                Base.append!(valueV, pValue);
            end
        end
    end

    # Transformation bounds (these are returned b/c the parameters are transformed)
    lbV = fill(pvec.pTransform.lb, size(valueV));
    ubV = fill(pvec.pTransform.ub, size(valueV));
    vv = ValueVector(valueV, lbV, ubV);
    return vv
end


"""
    $(SIGNATURES)

Make vector from a list of param vectors.
Output contains values, lower bounds, upper bounds.
"""
function make_vector(pvv :: Vector{ParamVector}, isCalibrated :: Bool)
    outV = Vector{ValueType}();
    lbV = Vector{ValueType}();
    ubV = Vector{ValueType}();
    for i1 = 1 : length(pvv)
        vVec = make_vector(pvv[i1], isCalibrated);
        append!(outV, values(vVec));
        append!(lbV, lb(vVec));
        append!(ubV, ub(vVec));
    end
    vv = ValueVector(outV, lbV, ubV);
    return vv
end


"""
    $(SIGNATURES)

Make a vector of values into a Dict

The inverse of `make_vector`.
Used to go back from vector to model parameters.

Undoes the parameter transformation from `make_vector`.

OUT
    pd :: Dict
        maps param names (symbols) to values
    iEnd :: Integer
        number of elements of `v` used up
"""
function vector_to_dict(pvec :: ParamVector, v :: Vector{T1},
    isCalibrated :: Bool) where T1 <: AbstractFloat

    n = length(pvec);
    @assert n > 0  "Parameter vector is empty"

    pd = Dict{Symbol, Any}();
    # Last index of `v` used so far
    iEnd = 0;
    for i1 in 1 : n
        p = pvec.pv[i1];
        if p.isCalibrated == isCalibrated
            nElem = length(p.defaultValue);
            if nElem == 1
                pValue = v[iEnd + 1];
            else
                idxV = (iEnd + 1) : (iEnd + nElem);
                pValue = reshape(v[idxV], size(p.defaultValue));
            end
            pValue = untransform_param(pvec.pTransform, p, pValue);
            pd[p.name] = pValue;
            iEnd += nElem;
        end
    end
    return pd, iEnd
end


"""
    $(SIGNATURES)

Set values in param vector from dictionary.
"""
function set_values_from_dict!(pvec :: ParamVector, d :: Dict{Symbol,Any})
    for (pName, newValue) in d
        change_value!(pvec, pName :: Symbol, newValue);
    end
    return nothing
end



"""
	$(SIGNATURES)

Set values in `pvecOld` from another `ParamVector` `pvecNew`. 
Only for values that are in both `ParamVector`s and that are `isCalibrated` in both.
Only if the size matches.

    Needs more testing +++++
"""
function set_values_from_pvec!(pvecOld :: ParamVector,  pvecNew :: ParamVector,
    isCalibrated :: Bool)

    dOld = make_dict(pvecOld, isCalibrated, true);
    dNew = make_dict(pvecNew, isCalibrated, true);
    pNameV = intersect(keys(dOld), keys(dNew));
    for pName in pNameV
        change_value!(pvecOld, pName, dNew[pName]);
    end
    return nothing
end



# ------------------
