## ------------  ParamInfo

export ParamInfo
# export set_value!

# function ParamInfo(pName :: Symbol, startIdx :: Integer, 
#     valueV :: T1, lbV :: T2, ubV :: T2) where {T1 <: AbstractArray, T2 <: Real}

#     sz = size(valueV);
#     return ParamInfo{T1}(pName, startIdx, valueV, fill(lbV, sz), fill(ubV, sz));
# end

function Base.isapprox(p1 :: ParamInfo{F1}, p2 :: ParamInfo{F1}; 
    atol :: Real = 1e-8) where F1
    return isequal(p1.pName, p2.pName)  &&
        # isapprox(p1.valueV, p2.valueV; atol)  &&
        isapprox(p1.lbV, p2.lbV; atol)  &&
        isapprox(p1.ubV, p2.ubV; atol);
end

Base.isapprox(p1 :: ParamInfo{F1}, p2 :: ParamInfo{F2}) where {F1, F2} = false;

lb(pInfo :: ParamInfo{F1}) where F1 = pInfo.lbV;
ub(pInfo :: ParamInfo{F1}) where F1 = pInfo.ubV;
n_values(pInfo :: ParamInfo{F1}) where F1 = length(pInfo.lbV);
indices(pInfo :: ParamInfo{F1}) where F1 <: Real = pInfo.startIdx;
indices(pInfo :: ParamInfo{F1}) where F1 = 
    pInfo.startIdx .+ (0 : (n_values(pInfo) - 1));

random_values(pInfo :: ParamInfo{F1}, rng :: AbstractRNG) where F1 = 
    pInfo.lbV .+ (pInfo.ubV .- pInfo.lbV) .* rand(rng, size(pInfo.lbV));
random_values(pInfo :: ParamInfo{F1}, rng :: AbstractRNG) where F1 <: Real = 
    pInfo.lbV .+ (pInfo.ubV .- pInfo.lbV) .* rand(rng);

# Reshape an input to match dimensions of ParamInfo.
reshape_vector(pInfo :: ParamInfo{F1}, v :: F1) where F1 <: Real = v;
reshape_vector(pInfo :: ParamInfo{F1}, v) where F1 <: AbstractArray{<:Real} = 
    reshape(v, size(pInfo.lbV));


# function set_value!(pInfo :: ParamInfo{F1}, v :: Real) where F1 <: Real
#     pInfo.valueV = v;
# end

# function set_value!(pInfo :: ParamInfo{F1}, v :: AbstractArray{F2}) where {F1 <: Real, F2 <: Real}
#     pInfo.valueV = only(v);
# end

# function set_value!(pInfo :: ParamInfo{<: AbstractArray{F1}}, v :: AbstractArray{F2}) where {F1 <: Real, F2 <: Real}
#     pInfo.valueV = reshape(v, size(pInfo.lbV));
# end

# function value_from_vector!(pInfo :: ParamInfo{F1}, 
#     valueV :: AbstractVector{F1}) where F1 <: Real
#     pInfo.valueV = valueV[pInfo.startIdx];
# end

# function value_from_vector!(pInfo :: ParamInfo{<:AbstractArray{F1}}, 
#     valueV :: AbstractVector{F1}) where F1 <: Real
#     pInfo.valueV = reshape(valueV[indices(pInfo)], size(pInfo.lbV));
# end

function make_test_param_info(pName, sz; startIdx = 10)
    if isempty(sz)
        lbV = 0.3;
        ubV = 5.8;
        # valueV = 3.5;
    else
        lbV = fill(0.3, sz);
        ubV = fill(5.8, sz);
        # valueV = 0.3 .* lbV .+ 0.7 .* ubV;
    end
    ParamInfo(pName, startIdx, lbV, ubV);
end


## ------------  ValueVector

# ValueVector
# export ValueVector, set_values!, values, lb, ub


ValueVector{F1}() where F1 = ValueVector{F1}(OrderedDict{Symbol, ParamInfo}());

function make_test_value_vector(n)
    vv = ValueVector{ValueType}();
    startIdx = 1;
    for j = 1 : n
        pName = Symbol("p$j");
        if j == 1
            sz = ();
        elseif j == 2
            sz = (j, );
        else
            sz = (j, 2);
        end
        vv.d[pName] = make_test_param_info(pName, sz; startIdx);
        nElem = prod(sz);
        startIdx += nElem;
    end
    return vv
end


function validate_param_match(pvec :: ParamVector, vv :: ValueVector{F1}) where F1
    isValid = true;
    nCal, _ = n_calibrated_params(pvec);
    if length(vv) != nCal
        isValid = false;
        @warn """
            No of calibrated params differs for $pvec
            pvec: $(nCal)
            vv:   $(length(vv))
            """;
    end

    if isValid  &&  (length(vv) > 0)
        pList = calibrated_params(pvec);
        for p in pList
            pName = name(p);
            if haskey(vv.d, pName)
                pInfo = vv.d[pName];
                if size(calibrated_value(p)) != size(lb(pInfo))
                    isValid = false;
                    @warn "Size mismatch for $pName";
                end
            else
                isValid = false;
                @warn "Param $pName missing from ValueVector";
            end
        end
    end
    return isValid
end


function validate_vv(vv :: ValueVector{F1}) where F1
    isValid = true;
    isValid = isValid  &&  validate_indices(vv);
    return isValid
end

function validate_indices(vv :: ValueVector{F1}) where F1
    isValid = true;
    nValues = n_values(vv);
    if nValues > 0
        takenV = zeros(Int, nValues);
        for (_, pInfo) in vv.d
            # This can be a Range of scalar.
            idxV = indices(pInfo) .- start_index(vv) .+ 1;
            if idxV[1] < 1
                @warn "Indices below start index";
                isValid = false;
            end
            if last(idxV) > nValues
                @warn "Indices past last index";
                isValid = false;
            end
            # Must make this a range for broadcasting to work
            isValid  &&  (takenV[first(idxV) : last(idxV)] .+= 1);
        end
        isValid = all(takenV .== 1);
    end
    return isValid
end

Base.isempty(vv :: ValueVector{F1}) where F1 = 
    n_values(vv) == 0;
Base.length(vv :: ValueVector{F1}) where F1 = length(vv.d);
    
"""
	$(SIGNATURES)

Total number of scalar values across all parameters.
"""
function n_values(vv :: ValueVector{F1}) where F1
    nValues = 0;
    for (_, pInfo) in vv.d
        nValues += n_values(pInfo);
    end
    return nValues
end

function start_index(vv :: ValueVector{F1}) where F1
    (_, pInfo) = first(vv.d);
    return pInfo.startIdx;
end

Base.last(vv :: ValueVector{F1}) where F1 = vv.d[last(collect(keys(vv.d)))];

function last_index(vv :: ValueVector{F1}) where F1
    pInfo = last(vv);
    return last(indices(pInfo))
end


# values(vv :: ValueVector{F1}) where F1 = vv.valueV;
# lb(vv :: ValueVector{F1}) where F1 = vv.lbV;
# ub(vv :: ValueVector{F1}) where F1 = vv.ubV;
# pnames(vv :: ValueVector{F1}) where F1 = vv.pNameV;
# Base.length(vv :: ValueVector{F1}) where F1 = Base.length(vv.valueV);

function Base.isapprox(vv1 :: ValueVector{F1}, vv2 :: ValueVector{F1};
    atol :: Real = 1e-8) where F1

    if length(vv1.d) != length(vv2.d) 
        return false;
    end
    for (pName, pInfo1) in vv1.d
        if haskey(vv2.d, pName)
            pInfo2 = vv2.d[pName]
            if !isapprox(pInfo1, pInfo2; atol)
                return false
            end
        else
            return false
        end
    end
    return true
end


# """
# 	$(SIGNATURES)

# Set values from a Vector{Real}. These are usually the transformed values for the entire `ModelObject`.
# """
# function set_values!(vv :: ValueVector{F1}, valueV :: AbstractVector{F1}) where F1
#     @assert length(valueV) >= last_index(vv)  "Vector too short";
#     for (_, pInfo) in vv.d
#         set_value!(pInfo, valueV[indices(pInfo)]);
#     end
#     return nothing
# end


"""
	$(SIGNATURES)

Get *transformed* values for all parameters in the `ValueVector`.
"""
function get_values(pvec :: ParamVector, vv :: ValueVector{F1}) where F1
    # @assert isequal(get_object_id(pvec), get_object_id(vv))  """
    #     ObjectId mismatch: 
    #     $(get_object_id(pvec))  vs  $(get_object_id(vv))
    #     """;
    valueV = Vector{F1}();
    for (pName, pInfo) in vv.d
        p = retrieve(pvec, pName);
        @assert size(lb(pInfo)) == size(calibrated_value(p));
        append!(valueV, transform_param(pvec.pTransform, p));
    end

    return valueV
end


function random_guess(vv :: ValueVector{F1}, rng :: AbstractRNG) where F1
    guessV = Vector{F1}();
    for (_, pInfo) in vv.d
        rv = random_values(pInfo, rng);
        if rv isa Real
            push!(guessV, rv);
        else
            append!(guessV, vec(rv)); 
        end
    end
    return guessV
end


# ----------------