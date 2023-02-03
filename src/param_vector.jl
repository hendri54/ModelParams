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
        LinearTransformation{ValueType}())
end


function validate_pvec(pvec :: ParamVector; silent = true)
    isValid = true;
    for p in pvec
        isValid = isValid &&  validate(p; silent);
    end
    return isValid
end


function make_ordered_dict(v)
    d = OrderedDict{Symbol, AbstractParam}();
    for p in v
        d[p.name] = p;
    end
    return d
end

make_ordered_dict(v :: OrderedDict{Symbol, AbstractParam}) = v;


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
function object_id_matches(pvec :: ParamVector, objId :: ObjectId)
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
    $(SIGNATURES)

Returns a named parameter and its index in the `ParamVector`.
First occurrence. Returns `nothing` if not found.
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
        return pvalue(p)
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

function calibrated_value(pvec :: ParamVector, pName :: Symbol)
    return calibrated_value(retrieve(pvec, pName));
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

List of calibrated or not calibrated parameters. Returns vector of `Param`.
"""
function calibrated_params(pvec :: ParamVector; isCalibrated :: Bool = true)
    return all_params(pvec; isCalibrated)
end

"""
	$(SIGNATURES)

Vector of all parameters, including nested objects. Optionally filter by calibration status.
"""
function all_params(pvec :: ParamVector; isCalibrated = nothing)
    pList = Vector{AbstractParam}();
    for (k, p) in pvec.pv
        if isnothing(isCalibrated)  ||   (is_calibrated(p) == isCalibrated)
            push!(pList, p);
        end
    end
    return pList
end


"""
    $(SIGNATURES)

Number of calibrated or fixed parameters and their total element count.
"""
function n_calibrated_params(pvec :: ParamVector; isCalibrated :: Bool = true)
    pList = calibrated_params(pvec; isCalibrated);
    nParams = length(pList);
    nElem = 0;
    for p in pList
        if isCalibrated
            pVal = calibrated_value(p);
            @assert !isnothing(pVal)  "calibrated value nothing: $pvec / $p";
            nCal = length(pVal);
        else
            nCal = 0;
        end
        if isCalibrated
            nElem += nCal;
        else
            nElem += (length((pvalue(p))) - nCal);
        end
    end
    return nParams, nElem
end


## ------------  Modify

"""
	$(SIGNATURES)

Set bounds for a parameter. Input must support `retrieve` for a `Param`.
"""
function set_bounds!(pvec, pName :: Symbol; lb = nothing, ub = nothing)
    p = retrieve(pvec, pName);
    @assert !isnothing(p)  "$pName not found in $pvec";
    set_bounds!(p; lb, ub);
end



"""
    $(SIGNATURES)

Append a `Param` to a `ParamVector`
"""
function append!(pvec :: ParamVector,  p :: AbstractParam)
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
function replace!(pvec :: ParamVector, p :: AbstractParam)
    pvec.pv[p.name] = p;
    return nothing
end


function set_calibration_status_all_params!(pvec :: ParamVector, isCalibrated :: Bool)
    for p in calibrated_params(pvec; isCalibrated = !isCalibrated)
        set_calibration_status!(p, isCalibrated);
    end
end


"""
	$(SIGNATURES)

Set default values for all parameters to values. 
Useful for fixing parameters at previously calibrated values.
"""
function set_default_values_all_params!(pvec :: ParamVector)
    for p in pvec
        set_default_value!(p, pvalue(p));
    end
end


function set_default_value!(pvec :: ParamVector, pName :: Symbol, v)
    p = retrieve(pvec, pName);
    set_default_value!(p, v);
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
function change_value!(pvec :: ParamVector, pName :: Symbol, newValue;
    skipInvalidSize :: Bool = false
    )
    @assert param_exists(pvec, pName)  "$pName does not exist";
    p = retrieve(pvec, pName);
    oldValue = set_value!(p, newValue; skipInvalidSize);

    # if size(default_value(p)) == size(newValue)  
    #     oldValue = set_value!(p, newValue; skipInvalidSize);
    # else
    #     @warn("""
    #         Wrong size for $p in $pvec
    #         Given: $(size(newValue))
    #         Expected: $(size(default_value(p)))
    #         """);
    #     if skipInvalidSize
    #         oldValue = value(p);
    #     else 
    #         error("Stopped");
    #     end
    # end
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
        pList = calibrated_params(pvec; isCalibrated);
    end
    n = length(pList);

    if isempty(pList)
        dataM = nothing;
    else
        # dataM = Matrix{String}(undef, n, 4);
        dataM = ParamTable(n);
        for (j, p) in enumerate(pList)
            set_row!(dataM, j, string(name(p)), lsymbol(p), 
                p.description, formatted_value(pvalue(p)));
        end
    end
    return dataM
end


# Find parameters that are close to bounds
function find_close_to_bounds(pvec :: ParamVector; rtol = 0.01)
    pList = calibrated_params(pvec);
    pCloseV = Vector{AbstractParam}();
    for p in pList
        if close_to_bounds(p; rtol = rtol)
            push!(pCloseV, p);
        end
    end
    return pCloseV
end


## -------------  Compare


function compare_params(pvec1 :: ParamVector, pvec2 :: ParamVector; 
    ignoreCalibrationStatus :: Bool = true)

    pMiss1 = missing_params(pvec1, pvec2);
    pMiss2 = missing_params(pvec2, pvec1);
    pDiff = find_param_diffs(pvec1, pvec2; ignoreCalibrationStatus = true);
    return pMiss1, pMiss2, pDiff
end


# List params that are in p2V but not in p1V
function missing_params(pvec1 :: ParamVector, pvec2 :: ParamVector)
    missList = Vector{Symbol}();
    for p in pvec2
        pName = name(p);
        if !param_exists(pvec1, pName)
            push!(missList, pName);
        end
    end
    return missList
end

# List all params that are in both vectors, but differ
function find_param_diffs(pvec1 :: ParamVector, pvec2 :: ParamVector;
    ignoreCalibrationStatus :: Bool = true)

    diffList = Dict{Symbol, Any}();
    for p1 in pvec1
        pName = name(p1);
        if param_exists(pvec2, pName)
            diffs = param_diffs(p1, retrieve(pvec2, pName); ignoreCalibrationStatus);
            if !isempty(diffs)
                diffList[pName] = diffs;
            end
        end
    end
    return diffList
end

param_diffs(p1, p2) = [:type];

function param_diffs(p1 :: T1, p2 :: T1;
    ignoreCalibrationStatus :: Bool = true) where T1 <: AbstractParam

    diffs = Vector{Symbol}();
    if !isequal(pvalue(p1), pvalue(p2))
        push!(diffs, :value);
    end
    if !ignoreCalibrationStatus
        if is_calibrated(p1) != is_calibrated(p2)
            push!(diffs, :calibration);
        end
    end
    return diffs
end



## --------------  Dicts and Vectors

"""
    $(SIGNATURES)

Collect calibrated values or default values into Dict.
Used to go back and forth between guess and model parameters.
All values are stored, even if only some are calibrated.

# Arguments
- `valueType`: `:defaultValue`, `:value`, or `:calibratedValue`. Determines which of those is stored.
"""
function make_dict(pvec :: ParamVector; isCalibrated :: Bool, valueType :: Symbol)

    pd = Dict{Symbol, Any}()
    pList = calibrated_params(pvec; isCalibrated);
    for p in pList
        if valueType == :value
            v = pvalue(p);
        elseif valueType == :defaultValue
            v = default_value(p);
        elseif valueType == :calibratedValue
            v = calibrated_value(p);
        else
            error("Unknown valueType: $valueType");
        end
        # Copy is important. Otherwise changing the values later will change the dict.
        pd[p.name] = copy(v);
    end
    return pd
end


# Typically, useValues when calibrated; defaults otherwise
# make_dict(pvec :: ParamVector; isCalibrated :: Bool) = 
#     make_dict(pvec; isCalibrated, useValues = isCalibrated)



# """
#     $(SIGNATURES)

#     Make a vector of values into a Dict

#     The inverse of `make_guess`.
#     Used to go back from vector to model parameters.
    
#     Undoes the parameter transformation from `make_guess`.
    
#     OUT
#         pd :: Dict
#             maps param names (symbols) to values
#         iEnd :: Integer
#             last element of `v` used up
# """
# function vector_to_dict(pvec :: ParamVector, vVec :: ValueVector,
#     isCalibrated :: Bool; startIdx = 1)

#     n = length(pvec);
#     @assert n > 0  "$pvec vector is empty"
#     pList = calibrated_params(pvec, isCalibrated);
#     v = get_values(vVec);
#     pNameV = pnames(vVec);

#     pd = Dict{Symbol, Any}();
#     # Last index of `v` used so far
#     iEnd = startIdx - 1;
#     for p in pList
#         nElem = length(default_value(p));
#         if isa(default_value(p), AbstractFloat)
#             vIdxV = iEnd + 1;
#             pValue = v[vIdxV];
#         elseif isa(default_value(p), AbstractArray)
#             vIdxV = iEnd .+ (1 : nElem);
#             pValue = reshape(v[vIdxV], size(default_value(p)));
#         else
#             pType = typeof(default_value(p));
#             error("Unexpected type: $pType")
#         end
#         iEnd += nElem;
#         pd[name(p)] = untransform_param(pvec.pTransform, p, pValue);
#         @assert all(isequal.(name(p),  pNameV[vIdxV]))  """
#             Name mismatch:  $(get_object_id(pvec)) $(name(p))
#             Values: $pValue
#             Indices: $vIdxV
#             Names expected: $(pNameV[vIdxV])
#             $startIdx
#             """
#     end
#     return pd, iEnd
# end


"""
    $(SIGNATURES)

Set values in param vector from dictionary.
"""
function set_values_from_dict!(pvec :: ParamVector, d :: D1;
    skipInvalidSize :: Bool = false) where D1 <: AbstractDict
    for (pName, newValue) in d
        change_value!(pvec, pName :: Symbol, newValue;  skipInvalidSize);
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
    isCalibrated :: Bool;
    skipInvalidSize :: Bool = false
    )

    for (pName, p) in pvecNew.pv
        if param_exists(pvecOld, pName)  &&  is_calibrated(p)
            pOld = retrieve(pvecOld, pName);
            if is_calibrated(pOld)
                newValue = calibrated_value(p);
                set_calibrated_value!(pOld, newValue; skipInvalidSize);
            end
        end
    end

    # dOld = make_dict(pvecOld; isCalibrated, useValues = true);
    # dNew = make_dict(pvecNew; isCalibrated, useValues = true);
    # pNameV = intersect(keys(dOld), keys(dNew));
    # for pName in pNameV
    #     change_value!(pvecOld, pName, dNew[pName]; skipInvalidSize);
    # end
    return nothing
end


## -----------  Testing

# Make a ParamVector for testing
# Alternates between calibrated and fixed parameters
function make_test_pvector(n :: Integer; objId :: Symbol = :obj1,
    offset :: Float64 = 0.0)

    pv = ParamVector(ObjectId(objId));
    for i1 = 1 : n
        if i1 == 1
            p = make_test_cal_array(:p1, 2; offset);
        else
            p = init_parameter(i1; offset = offset);
        end
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