## --------------  Guess

export Guess
export make_guess, set_params_from_guess!, random_guess, n_values
export validate_guess

Guess{T}() where T = Guess(OrderedDict{ObjectId, ValueVector{T}}());

Base.isapprox(g1 :: Guess{T1}, g2 :: Guess{T2}; atol = 1e-8) where {T1, T2} = false;

function Base.isapprox(g1 :: Guess{T}, g2 :: Guess{T}; atol = 1e-8) where T
    if length(g1.d) != length(g2.d)
        return false
    end
    for (oId, vv1) in g1.d
        if haskey(g2.d, oId)
            vv2 = g2.d[oId]
            if !isapprox(vv1, vv2; atol)
                return false
            end
        else
            return false
        end
    end
    return true
end

lb(g :: Guess{F1}) where F1 = fill(F1(TransformationLb), (n_values(g), ));
ub(g :: Guess{F1}) where F1 = fill(F1(TransformationUb), (n_values(g), ));


function validate_guess(x :: ModelObject, g :: Guess{F1}) where F1
    isValid = validate_guess(g);
    isValid = isValid  &&  validate_param_match(x, g);
    return isValid
end


function validate_guess(g :: Guess{F1}) where F1
    isValid = true;
    n = n_values(g);
    if n > 0
        takenV = zeros(Int, n);
        for (_, vv) in g.d
            if !isempty(vv)
                isValid = isValid && validate_vv(vv);
                takenV[start_index(vv) : last_index(vv)] .+= 1;
            end
        end
        isValid = isValid  &&  all(takenV .== 1);
    end
    return isValid
end

# Check that parameters in Guess match calibrated parameters in ModelObject
function validate_param_match(x :: ModelObject, g :: Guess{F1}) where F1
    isValid = true;
    pvecV = collect_pvectors(x);
    if n_value_vectors(g) != length(pvecV)
        @warn "No of ParamVectors differs: $x";
        isValid = false;
    end
    if isValid
        for (_, pvec) in pvecV
            objId = get_object_id(pvec);
            nCal, _ = n_calibrated_params(pvec);
            if haskey(g.d, objId)
                vVec = g.d[objId];
                isValid = isValid  &&  validate_param_match(pvec, vVec);
            elseif (nCal > 0) 
                @warn """
                    Guess has no entry for ParamVector with calibrated params
                    $objId
                    """;
                isValid = false;
            end
        end
    end
    return isValid
end



get_value_vector(guess :: Guess{T}, objId :: ObjectId) where T = 
    guess.d[objId];

n_value_vectors(g :: Guess{T1}) where T1 = length(g.d);


"""
	$(SIGNATURES)

Total number of scalar values (elements in all arrays) in all parameters.
"""
function n_values(g :: Guess{T}) where T
    n = 0;
    for (_, vv) in g.d
        n += n_values(vv);
    end
    return n
end


"""
	$(SIGNATURES)

Values as a vector. Transformed.
"""
function get_values(o :: ModelObject, guess :: Guess{F1}) where F1
    pvecV = collect_pvectors(o);
    return get_values(pvecV, guess);
end

function get_values(pvecV :: PVectorCollection, guess :: Guess{F1}) where F1
    valueV = Vector{F1}();
    for (objId, vv) in guess.d
        pvec = find_pvector(pvecV, objId);
        @assert !isnothing(pvec);
        pValueV = get_values(pvec, vv);
        if !isempty(pValueV)
            append!(valueV, pValueV);
            @assert length(valueV) == last_index(vv);
        end
    end
    return valueV
end


# """
# 	$(SIGNATURES)

# Set values from a Vector{Real}. These are usually the transformed values.
# """
# function set_values!(guess :: Guess{F1}, valueV :: AbstractVector{F1}) where F1
#     for (_, vv) in guess.d
#         set_values!(vv, valueV)
#     end
#     return nothing
# end


"""
    $(SIGNATURES)

Make vector of parameters and bounds for an object.
Including nested objects.
This should be done only once to guarantee that order never changes.
"""
function make_guess(m :: ModelObject)
    pvecV = collect_pvectors(m);
    @assert !isempty(pvecV)  "$m contains no ParamVectors"
    vv = make_guess(pvecV);
    return vv
end

"""
    $(SIGNATURES)

Make vector from a list of param vectors.
Output contains values, lower bounds, upper bounds.
"""
function make_guess(pvv :: PVectorCollection)
    vv = Guess{ValueType}();
    startIdx = 1;
    for (objId, pv) in pvv
        vVec = make_value_vector(pv, startIdx);
        vv.d[objId] = vVec;
        startIdx += n_values(vVec);
    end
    @assert validate_guess(vv);
    return vv
end

"""
    $(SIGNATURES)

Make vector of values, lb, ub for optimization algorithm.
Vectors are transformed using the `ParameterTransformation` specified in the `ParamVector`.
Returns a `ValueVector`.
"""
function make_value_vector(pvec :: ParamVector,  startIdx :: Integer)
    T1 = ValueType;
    pList = calibrated_params(pvec);
    n, nElem = n_calibrated_params(pvec);

    vv = ValueVector{T1}();
    idxLast = startIdx - 1;
    for p in pList
        pValue = transform_param(pvec.pTransform,  p);
        pLen = length(pValue);
        # pIdxV = idxLast .+ (1 : pLen);
        vv.d[p.name] = ParamInfo(p.name, idxLast + 1, 
            make_bounds(pvec.pTransform, size(pValue))...);
        idxLast += pLen;
    end
    @assert (idxLast - startIdx + 1) == nElem;
    return vv
end

function make_bounds(pTransform, sz)
    lbnd = param_lb(pTransform);
    ubnd = param_ub(pTransform);
    if !isempty(sz)
        lbnd = fill(lbnd, sz);
        ubnd = fill(ubnd, sz);
    end
    return lbnd, ubnd
end


"""
    $(SIGNATURES)

Make vector of guesses into model parameters. For object and children.
This changes the values in `m` and in its `pvector`.
"""
function set_params_from_guess!(m :: ModelObject, guess :: Guess{F1},
    guessV :: AbstractVector{F1}) where F1
    objV = collect_model_objects(m);
    # Copy param vectors into model
    for obj in objV 
        set_own_params_from_guess!(obj, guess, guessV);
    end
end
    
"""
    $(SIGNATURES)

Copy values from a *vector* of `ParamVector` into a *vector* of `ModelObject`s.
The order of the objects must match the order of the `ParamVector`s.
The order of the values in `vAllInV` must match the order of `ParamVector`s.
Returns `true` if all values used; `false` otherwise.
Also ensures that all fixed parameters match `ParamVector`.
"""
function set_own_params_from_guess!(o, g :: Guess{F1}, guessV :: AbstractVector{F1}) where F1
    if has_pvector(o)
        objId = get_object_id(o);
        vv = get_value_vector(g, objId);
        set_own_params_from_vector!(o, vv, guessV);
        @assert check_own_calibrated_params(o, get_pvector(o))
        @assert check_own_fixed_params(o, get_pvector(o))
        # startIdx = idxLast + 1;
    end

    # if startIdx == length(vAll) + 1
    #     success = true;
    # else
    #     success = false;
    #     @warn "Not all values used: $(startIdx - 1)  vs  $(length(vAll))"
    # end
    # return success
end

"""
    $(SIGNATURES)

Copy values from vector into param vector and object.
Calibrated parameters.
Also ensures that fixed parameters are set according to `ParamVector`.
Uses the values in `vAll` starting from (optional) `startIdx`.
Returns index of last value used.
Order in `vAll` must match order in `pvec`. E.g., because `vAll` is generated by `make_guess`.
"""
function set_own_params_from_vector!(x :: ModelObject, vAll :: ValueVector{F1},
    guessV :: AbstractVector{F1}) where F1
    pvec = get_pvector(x);
    set_params_from_vector!(pvec, vAll, guessV);
    # d11, idxEnd = vector_to_dict(pvec, vAll, true; startIdx = startIdx);
    # set_values_from_dict!(pvec, d11);
    # This is key! It copies the values (calibrated and fixed) from the ParamVector into the ModelObject.
    sync_own_values!(x);
    return nothing
end


function set_params_from_vector!(pvec :: ParamVector, vv :: ValueVector{F1},
    guessV :: AbstractVector{F1}) where F1
    for (pName, pInfo) in vv.d
        set_value_from_pinfo!(pvec, pInfo, guessV; isCalibrated = true);
    end
end

function set_value_from_pinfo!(pvec :: ParamVector, 
    pInfo :: ParamInfo{T},
    guessV :: AbstractVector{F1};
    isCalibrated = true) where {F1, T}

    p = retrieve(pvec, pInfo.pName);
    @assert size(calibrated_value(p)) == size(param_lb(pInfo));
    @assert !isnothing(p)  "Param $(pInfo.pName) not found in $pvec";
    if is_calibrated(p) == isCalibrated
        valV = reshape_vector(pInfo, guessV[indices(pInfo)]);
        v = untransform_param(pvec.pTransform, p, valV);
        set_calibrated_value!(p, v);
    end
end


function random_guess(g :: Guess{F1}, rng :: AbstractRNG) where F1
    param_lb(g) .+ (param_ub(g) .- param_lb(g)) .* rand(rng, n_values(g));
end


# ----------