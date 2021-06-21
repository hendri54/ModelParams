"""
	$(SIGNATURES)

Constructors for ParamVector
"""
function ParamVector(id :: ObjectId)
    return ParamVector(objId = id)
end

# With default parameter transformation
# Providing vector of Param or an OrderedDict.
function ParamVector(id :: ObjectId, pv)
    return ParamVector(id, 
        make_ordered_dict(pv), 
        LinearTransformation(lb = 1.0, ub = 2.0))
end

function make_ordered_dict(v)
    d = OrderedDict{Symbol, Param}();
    for p in v
        d[p.name] = p;
    end
    return d
end

make_ordered_dict(v :: OrderedDict{Symbol, Param}) = v;


function Base.show(io :: IO,  pvec :: ParamVector)
    n = length(pvec);
    idStr = make_string(pvec.objId);
    print(io,  "ParamVector $idStr of length $n");
    # if n > 0
    #     for p in pvec
    #         println(io, "  ", p);
    #     end
    # end
    return nothing
end

ModelObjectsLH.get_object_id(pv :: ParamVector) = pv.objId;
# ModelObjectsLH.has_object_id(pv :: ParamVector) = true;
Base.length(pvec :: ParamVector) = Base.length(pvec.pv);
Base.isempty(pvec :: ParamVector) = Base.isempty(pvec.pv);


# Check that param vector matches model object
function check_match(pvec :: ParamVector, objId :: ObjectId)
    return isequal(pvec.objId, objId)
end


## ----------  Retrieve

# Allows to access values simply as `p[j]`.
# But access by name is far more efficient.
function getindex(pvec :: ParamVector, j :: Integer)
    @argcheck j <= Base.length(pvec.pv);
    k = collect(keys(pvec.pv))[j];
    return pvec.pv[k]
end


function Base.iterate(pvec :: ParamVector)
    if isempty(pvec) 
        return nothing
    else
        return pvec[1], 1
    end
end

function Base.iterate(pvec :: ParamVector, s)
    if s >= length(pvec)
        return nothing
    else
        return pvec[s+1], s+1
    end
end

Base.eltype(pvec :: ParamVector) = Param;


"""
    retrieve

Returns a named parameter and its index in the `ParamVector`.
First occurrence. Returns 0 if not found.
"""
function retrieve(pvec :: ParamVector, pName :: Symbol)
    return get(pvec.pv, pName, nothing);
end

# param_index(pvec :: ParamVector, pName :: Symbol) = 
#     findfirst(x -> x == pName,  collect(keys(pvec.pv)));
    # findfirst(x -> isequal(x.name, pName),  pvec.pv);


"""
	$(SIGNATURES)

Is this parameter calibrated?
"""
function is_calibrated(pvec :: ParamVector, pName :: Symbol)
    @assert param_exists(pvec, pName)  "Not found: $pName";
    return is_calibrated(retrieve(pvec, pName))
end


"""
	$(SIGNATURES)

Does a `Param` named `pName` exist in `ParamVector pvec`?
"""
param_exists(pvec :: ParamVector, pName :: Symbol) =
    haskey(pvec.pv, pName);


"""
	$(SIGNATURES)

Return the value of a parameter from a `ParamVector`. 
Returns `nothing` if not found.
"""
function param_value(pvec :: ParamVector, pName :: Symbol)
    p = retrieve(pvec, pName);
    if isnothing(p) 
        return nothing
    else
        return value(p)
    end
end


"""
	$(SIGNATURES)

Return the default value of a parameter from a `ParamVector`. 
Returns `nothing` if not found.
"""
function param_default_value(pvec :: ParamVector, pName :: Symbol)
    p = retrieve(pvec, pName);
    if isnothing(p) 
        return nothing
    else
        return default_value(p)
    end
end


# """
# 	$(SIGNATURES)

# Return indices of all parameters with a given calibration status.
# """
# function indices_calibrated(pvec :: ParamVector, isCalibrated :: Bool)
#     n = length(pvec);
#     if n > 0
#         isCalV = [pvec.pv[k].isCalibrated  for k in keys(pvec.pv)];
#         # isCalV = [pvec.pv[j].isCalibrated  for j in 1 : n];
#         idxV = findall(isCalV .== isCalibrated);
#     else
#         idxV = Vector{Int}();
#     end
#     return idxV
# end


"""
	$(SIGNATURES)

List of calibrated or not calibrated parameters. Returns vector of names.
"""
function calibrated_params(pvec :: ParamVector, isCalibrated :: Bool)
    pList = Vector{Param}();
    for (k, p) in pvec.pv
        if p.isCalibrated == isCalibrated
            push!(pList, p);
        end
    end
    return pList
end


"""
    $(SIGNATURES)

Number of calibrated parameters and their total element count.
"""
function n_calibrated_params(pvec :: ParamVector, isCalibrated :: Bool)
    # idxV = indices_calibrated(pvec, isCalibrated);
    pList = calibrated_params(pvec, isCalibrated);
    nParams = length(pList);
    nElem = 0;
    for p in pList
        nElem += length(p.value);
    end
    return nParams, nElem
end


## ------------  Modify

"""
    $(SIGNATURES)

Append a `Param` to a `ParamVector`
"""
function append!(pvec :: ParamVector,  p :: Param)
    @assert !param_exists(pvec, p.name)  "$(p.name) already exists";
    pvec.pv[p.name] = p;
    return nothing
end

"""
	$(SIGNATURES)

Remove the parameter names `pName` from `pvec`.
"""
function remove!(pvec :: ParamVector, pName :: Symbol)
    @assert haskey(pvec.pv, pName)  "$pName does not exist";
    delete!(pvec.pv, pName);
    return nothing
end

"""
	$(SIGNATURES)

Replace a parameter with a new parameter `p`. Without changing the order.
"""
function replace!(pvec :: ParamVector, p :: Param)
    pvec.pv[p.name] = p;
    return nothing
end

"""
	$(SIGNATURES)

Set whether or not a parameter is calibrated.
"""
function change_calibration_status!(pvec :: ParamVector, pName :: Symbol,
    doCal :: Bool)

    @assert param_exists(pvec, pName)  "$pName does not exist";
    p = retrieve(pvec, pName);
    if doCal
        calibrate!(p);
    else
        fix!(p);
    end
end

calibrate!(pvec :: ParamVector, pName :: Symbol) = 
    change_calibration_status!(pvec, pName, true);
fix!(pvec :: ParamVector, pName :: Symbol) = 
    change_calibration_status!(pvec, pName, false);


"""
	$(SIGNATURES)

Change the value of parameter `pName`.
"""
function change_value!(pvec :: ParamVector, pName :: Symbol, newValue)
    @assert param_exists(pvec, pName)  "$pName does not exist";
    p = retrieve(pvec, pName);
    @assert size(p.defaultValue) == size(newValue)  """
        Wrong size for $pName in $pvec
        Given: $(size(newValue))
        Expected: $(size(p.defaultValue))
        """
    oldValue = set_value!(p, newValue);
    return oldValue
end


## ------------------  Reporting

"""
    $(SIGNATURES)

Reports calibrated (or fixed) parameters for one ParamVector as a `PrettyTable`.
"""
function report_params(pvec :: ParamVector, isCalibrated :: Bool;
    io :: IO = stdout,  closeToBounds :: Bool = false)

    objId = make_string(pvec.objId);
    dataM = param_table(pvec, isCalibrated;  closeToBounds = closeToBounds);

    if isnothing(dataM)
        println(io, "\t$objId:  Nothing to report");
    else
        # Reports description, name, value (not symbol)
        pretty_table(io, 
            [get_descriptions(dataM) get_names(dataM) get_values(dataM)]; 
            header = [objId, " ", " "]);
    end
    return nothing
end


"""
	$(SIGNATURES)

Table with calibrated (or fixed) parameters.
Optionally reports params that are close to bounds.
Columns are name, description, value, symbol.
This is for reporting during a computation.
"""
function param_table(pvec :: ParamVector, isCalibrated :: Bool;
    closeToBounds :: Bool = false)

    if closeToBounds
        pList = find_close_to_bounds(pvec);
    else
        pList = calibrated_params(pvec, isCalibrated);
    end
    n = length(pList);

    if isempty(pList)
        dataM = nothing;
    else
        # dataM = Matrix{String}(undef, n, 4);
        dataM = ParamTable(n);
        for (j, p) in enumerate(pList)
            set_row!(dataM, j, string(name(p)), lsymbol(p), 
                p.description, formatted_value(p.value));
        end
    end
    return dataM
end


# Find parameters that are close to bounds
function find_close_to_bounds(pvec :: ParamVector; rtol = 0.01)
    pList = calibrated_params(pvec, true);
    pCloseV = Vector{Param}();
    for p in pList
        if close_to_bounds(p; rtol = rtol)
            push!(pCloseV, p);
        end
    end
    return pCloseV
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
    pList = calibrated_params(pvec, isCalibrated);
    for p in pList
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
    pList = calibrated_params(pvec, isCalibrated);
    n, nElem = n_calibrated_params(pvec, isCalibrated);
    valueV = Vector{T1}(undef, nElem);
    pNameV = Vector{Symbol}(undef, nElem);

    idxLast = 0;
    for p in pList
        pValue = transform_param(pvec.pTransform,  p);
        pLen = length(pValue);
        pIdxV = idxLast .+ (1 : pLen);
        idxLast += pLen;
        if pLen == 1
            valueV[pIdxV] .= pValue;
        else
            valueV[pIdxV] .= vec(pValue);
        end
        pNameV[pIdxV] .= p.name;
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
    pList = calibrated_params(pvec, isCalibrated);
    v = values(vVec);
    pNameV = pnames(vVec);

    pd = Dict{Symbol, Any}();
    # Last index of `v` used so far
    iEnd = startIdx - 1;
    for p in pList
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


## -----------  Testing

# Make a ParamVector for testing
# Alternates between calibrated and fixed parameters
function make_test_pvector(n :: Integer; objId :: Symbol = :obj1,
    offset :: Float64 = 0.0)

    pv = ParamVector(ObjectId(objId));
    for i1 = 1 : n
        p = init_parameter(i1; offset = offset);
        if isodd(i1)
            calibrate!(p);
        end
        ModelParams.append!(pv, p);
    end
    return pv
end

function init_parameter(i1 :: Integer;  offset :: Float64 = 0.0)
    pSym = Symbol("p$i1");
    pName = "param$i1";
    pDescr = "sym$i1";
    valueM = (offset + i1) .+ collect(1 : i1) * [1.0 2.0];
    return Param(pSym, pName, pDescr, valueM)
end



# ------------------
