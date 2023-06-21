export MParam, make_mapped_param;

"""
	$(SIGNATURES)

Constructor with keyword arguments.
"""
function make_mapped_param(name :: Symbol, defaultValue :: T1, lb :: T1, ub :: T1,
        isCalibrated :: Bool;
        description = string(name), symbol = string(name),
        pMap :: T2 = IdentityMap()) where {T1, T2 <: AbstractMap}

    p = MParam{T1,T2}(name, description, symbol, 
        deepcopy(defaultValue), defaultValue, lb, ub, isCalibrated, pMap);
    @assert validate(p; silent = false);
    return p
end

# Must produce reproducible values.
function make_test_mapped_param(name, sizeV, pMap;
        offset = 0.0, isCalibrated = true, rng = MersenneTwister(23))
    if pMap isa ScalarMap
        defaultValue = 2.0 + offset;
    elseif pMap isa GroupedMap
        ng = length(calibrated_groups(pMap));
        defaultValue = rand(rng, Float64, (ng,)) .+ offset;
    else
        defaultValue = rand(rng, Float64, sizeV) .+ offset;
    end
    if pMap isa IncreasingMap
        lb = zeros(size(defaultValue));
        ub = ones(size(defaultValue));
    else
        lb = defaultValue .- 1.0;
        ub = defaultValue .+ 1.0;
    end
    return make_mapped_param(name, defaultValue, 
        lb, ub, isCalibrated; pMap)
end


function validate(p :: MParam{F1, T1}; silent = true) where {F1, T1}
    isValid = true;

    pMap = pmeta(p);
    if pMap isa ScalarMap
        (default_value(p) isa Number)  ||  (isValid = false);
    end
    if !(default_value(p) isa Number)
        sizeV = size(default_value(p));
        (size(calibrated_value(p; returnIfFixed = true)) == sizeV)    ||  
            (isValid = false);
        (size(calibrated_lb(p)) == sizeV)  ||  (isValid = false);
        (size(calibrated_ub(p)) == sizeV)  ||  (isValid = false);
    end
    if pMap isa IncreasingMap
        all(0.0 .<= calibrated_lb(p) .<= calibrated_ub(p) .<= 1.0)  ||  
            (isValid = false);
    end
    if !isValid  &&  !silent
        @warn """
            Invalid MParam $p
            default value:  $(default_value(p))
            value:          $(calibrated_value(p))
            lb:             $(calibrated_lb(p))
            ub:             $(calibrated_ub(p))
        """
    end
    return isValid
end


"""
	$(SIGNATURES)

Retrieve value of a `Param`. User facing.
"""
# pvalue(p :: MParam) = pvalue(pmeta(p), p);
# pvalue(p :: MParam, j) = pvalue(pmeta(p), p, j);

# Not user facing. For calibration.
# default_value(p :: MParam) = default_value(pmeta(p), p);

pmeta(p :: MParam) = p.pMap;


## ------------  Show

Base.show(io :: IO,  p :: MParam) = 
    print(io, "MParam:  " * show_string(p));

function calibrated_string(p :: MParam)
    v = default_value(p);
    return calibrated_string(is_calibrated(p); fixedValue = v, nValues = length(v));
end

function type_description(p :: MParam)
    "MParam / " * type_description(pmeta(p));
end


## ----------  Change / update



# """
#     $(SIGNATURES)

# Change calibration status to `false`
# """
# function fix!(p :: MParam; pValue = nothing)
#     p.isCalibrated = false;
#     if !isnothing(pValue)
#         set_calibrated_value!(p, pValue);
#         set_default_value!(p, pValue);
#     end
#     return nothing
# end


# """
# 	$(SIGNATURES)

# Set a random value for an `AbstractParam`.
# """
# function set_random_value!(p :: MParam{F1, T1}, rng :: AbstractRNG) where {F1, T1}
#     sz = size(default_value(p));
#     newValue = calibrated_lb(p) .+ 
#         (calibrated_ub(p) .- calibrated_lb(p)) .* rand(rng, eltype(F1), sz);
#     set_calibrated_value!(p, newValue; skipInvalidSize = false);
# end


# -----------