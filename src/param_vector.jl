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
Base.length(pvec :: ParamVector) = Base.length(pvec.pv);
Base.isempty(pvec :: ParamVector) = Base.isempty(pvec.pv);


# Check that param vector matches model object
function check_match(pvec :: ParamVector, objId :: ObjectId)
    return isequal(pvec.objId, objId)
end


## ----------  Retrieve

# Allows to access values simply as `p[j]`
function getindex(pvec :: ParamVector, j :: Integer)
    @argcheck j <= Base.length(pvec.pv)
    return pvec.pv[j]
end

function Base.iterate(pvec :: ParamVector)
    if isempty(pvec) 
        return nothing
    else
        return pvec.pv[1], 1
    end
end

function Base.iterate(pvec :: ParamVector, s)
    if s >= length(pvec)
        return nothing
    else
        return pvec.pv[s+1], s+1
    end
end

Base.eltype(pvec :: ParamVector) = Param;


"""
    retrieve

Returns a named parameter and its index in the `ParamVector`.
First occurrence. Returns 0 if not found.
"""
function retrieve(pvec :: ParamVector, pName :: Symbol)
    idxOut = param_index(pvec, pName);
    if isnothing(idxOut)
        return nothing, 0
    else
        return pvec.pv[idxOut], idxOut
    end
end

param_index(pvec :: ParamVector, pName :: Symbol) = 
    findfirst(x -> isequal(x.name, pName),  pvec.pv);


"""
	$(SIGNATURES)

Does a `Param` named `pName` exist in `ParamVector pvec`?
"""
param_exists(pvec :: ParamVector, pName :: Symbol) =
    !isnothing(param_index(pvec, pName))


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


"""
    n_calibrated_params

Number of calibrated parameters and their total element count.
"""
function n_calibrated_params(pvec :: ParamVector, isCalibrated :: Bool)
    idxV = indices_calibrated(pvec, isCalibrated);
    nParams = length(idxV);
    nElem = 0;
    for i1 in idxV
        nElem += length(pvec.pv[i1].value);
    end
    return nParams, nElem
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

"""
	$(SIGNATURES)

Remove the parameter names `pName` from `pvec`.
"""
function remove!(pvec :: ParamVector, pName :: Symbol)
    _, idx = retrieve(pvec, pName);
    @assert (idx > 0)  "$pName does not exist"
    deleteat!(pvec.pv, idx);
    return nothing
end

"""
	$(SIGNATURES)

Replace a parameter with a new parameter `p`.
"""
function replace!(pvec :: ParamVector, p :: Param)
    remove!(pvec, p.name);
    append!(pvec, p);
    return nothing
end

"""
	$(SIGNATURES)

Set whether or not a parameter is calibrated.
"""
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

"""
	$(SIGNATURES)

Change the value of parameter `pName`.
"""
function change_value!(pvec :: ParamVector, pName :: Symbol, newValue)
    _, idx = retrieve(pvec, pName);
    @assert (idx > 0)  "$pName does not exist"
    oldValue = set_value!(pvec.pv[idx], newValue);
    return oldValue
end


## ------------------  Reporting

"""
    $(SIGNATURES)

Reports calibrated (or fixed) parameters for one ParamVector
"""
function report_params(pvec :: ParamVector, isCalibrated :: Bool;
    io :: IO = stdout,  closeToBounds :: Bool = false)

    objId = make_string(pvec.objId);
    dataM = param_table(pvec, isCalibrated;  closeToBounds = closeToBounds);

    if isnothing(dataM)
        println(io, "\t$objId:  Nothing to report");
    else
        pretty_table(io, dataM, [objId, " ", " "]);
    end
    return nothing
end


"""
	$(SIGNATURES)

Table with calibrated parameters.
Optionally reports params that are close to bounds.
Columns are name, description, value.
"""
function param_table(pvec :: ParamVector, isCalibrated :: Bool;
    closeToBounds :: Bool = false)

    if closeToBounds
        idxV = find_close_to_bounds(pvec);
    else
        idxV = indices_calibrated(pvec, isCalibrated);
    end
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


# Find parameters that are close to bounds
function find_close_to_bounds(pvec :: ParamVector; rtol = 0.01)
    idxV = indices_calibrated(pvec, true);
    idxCloseV = Vector{Int}();
    for j in idxV
        if close_to_bounds(pvec[j]; rtol = rtol)
            push!(idxCloseV, j);
        end
    end
    return idxCloseV
end


## --------------  Dicts and Vectors

"""
    $(SIGNATURES)

Collect values or default values into Dict.
Used to go back and forth between guess and model parameters.
"""
function make_dict(pvec :: ParamVector, isCalibrated :: Bool,
    useValues :: Bool)

    pd = Dict{Symbol, Any}()
    idxV = indices_calibrated(pvec, isCalibrated);
    for i1 in idxV
        p = pvec.pv[i1];
        if useValues
            pd[p.name] = p.value;
        else
            pd[p.name] = p.defaultValue;
        end
    end
    return pd
end


# Typically, useValues when calibrated; defaults otherwise
make_dict(pvec :: ParamVector, isCalibrated :: Bool) = 
    make_dict(pvec, isCalibrated, isCalibrated)


"""
    $(SIGNATURES)

Make vector of values, lb, ub for optimization algorithm.
Vectors are transformed using the `ParameterTransformation` specified in the `ParamVector`.
Returns a `ValueVector`.
"""
function make_vector(pvec :: ParamVector, isCalibrated :: Bool)
    T1 = ValueType;
    idxV = indices_calibrated(pvec, isCalibrated);
    n, nElem = n_calibrated_params(pvec, isCalibrated);
    valueV = Vector{T1}(undef, nElem);
    pNameV = Vector{Symbol}(undef, nElem);

    idxLast = 0;
    for i1 in idxV
        pValue = transform_param(pvec.pTransform,  pvec.pv[i1]);
        pLen = length(pValue);
        pIdxV = idxLast .+ (1 : pLen);
        idxLast += pLen;
        if pLen == 1
            valueV[pIdxV] .= pValue;
        else
            valueV[pIdxV] .= vec(pValue);
        end
        pNameV[pIdxV] .= name(pvec.pv[i1]);
        # # Append works for scalars, vectors, and matrices (that get flattened)
        # # Need to qualify - otherwise local append! is called
        # Base.append!(valueV, pValue);
    end
    @assert idxLast == nElem;

    # Transformation bounds (these are returned b/c the parameters are transformed)
    lbV = fill(pvec.pTransform.lb, size(valueV));
    ubV = fill(pvec.pTransform.ub, size(valueV));
    vv = ValueVector(valueV, lbV, ubV, pNameV);
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
            last element of `v` used up
"""
function vector_to_dict(pvec :: ParamVector, vVec :: ValueVector,
    isCalibrated :: Bool; startIdx = 1)

    n = length(pvec);
    @assert n > 0  "$pvec vector is empty"
    idxV = indices_calibrated(pvec, isCalibrated);
    v = values(vVec);
    pNameV = pnames(vVec);

    pd = Dict{Symbol, Any}();
    # Last index of `v` used so far
    iEnd = startIdx - 1;
    for i1 in idxV
        p = pvec.pv[i1];
        nElem = length(p.defaultValue);
        if isa(p.defaultValue, AbstractFloat)
            vIdxV = iEnd + 1;
            pValue = v[vIdxV];
        elseif isa(p.defaultValue, AbstractArray)
            vIdxV = iEnd .+ (1 : nElem);
            pValue = reshape(v[vIdxV], size(p.defaultValue));
        else
            pType = typeof(p.defaultValue);
            error("Unexpected type: $pType")
        end
        iEnd += nElem;
        pd[name(p)] = untransform_param(pvec.pTransform, p, pValue);
        @assert all(isequal.(name(p),  pNameV[vIdxV]))  """
            Name mismatch:  $(get_object_id(pvec)) $(name(p))
            Values: $pValue
            Indices: $vIdxV
            Names expected: $(pNameV[vIdxV])
            $startIdx
            """
    end
    return pd, iEnd
end


"""
    $(SIGNATURES)

Set values in param vector from dictionary.
"""
function set_values_from_dict!(pvec :: ParamVector, d :: D1) where D1 <: AbstractDict
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
"""
function set_own_values_from_pvec!(pvecOld :: ParamVector,  pvecNew :: ParamVector,
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
