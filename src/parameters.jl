## -----------  Param

"""
	$(SIGNATURES)

Constructor with keyword arguments.
"""
function make_param(name :: Symbol, defaultValue :: T1;
        description = string(name), symbol = string(name), 
        lb = defaultValue .- 0.001, ub = defaultValue .+ 0.001,
        isCalibrated = false) where T1

    return Param(name, description, symbol, 
        deepcopy(defaultValue), defaultValue, lb, ub, isCalibrated)
end

## Constructor when not calibrated (deprecated)
function Param(name :: Symbol, description :: T2, symbol :: T2, defaultValue :: T1) where {T1 <: Any,  T2 <: AbstractString}

    return Param(name, description, symbol, defaultValue, defaultValue,
        defaultValue .- 0.001, defaultValue .+ 0.001, false)
end

pmeta(p :: Param) = IdentityMap();  # stub +++++


function validate(p :: Param{F1}; silent = true) where F1
    sizeV = size(default_value(p));
    isValid = true;
    if !Base.isempty(pvalue(p))
        (size(pvalue(p)) == sizeV)  ||  (isValid = false);
    end
    if !Base.isempty(p.lb)
        (size(p.lb) == sizeV)  ||  (isValid = false);
        (size(p.ub) == sizeV)  ||  (isValid = false);
    end
    if !isValid  &&  !silent
        @warn """
            Invalid Param $p
            default value:  $(default_value(p))
            value:          $(pvalue(p))
            lb:             $(p.lb)
            ub:             $(p.ub)
        """
    end
    return isValid
end


# """
# 	$(SIGNATURES)

# Retrieve value of a `Param`.
# Deprecated. Use `pvalue` to avoid name conflicts with common symbol `value`.
# """
# value(p :: Param{F1}) where F1 = p.value;

"""
	$(SIGNATURES)

Retrieve value of a `Param`.
"""
pvalue(p :: Param) = pvalue(pmeta(p), p);
pvalue(p :: Param, j) = pvalue(pmeta(p), p, j);

pvalue(::IdentityMap, p :: Param) = p.value;
pvalue(::IdentityMap, p :: Param, j) = p.value[j];

default_value(p :: Param) = default_value(pmeta(p), p);
default_value(::IdentityMap, p :: Param) = p.defaultValue;
   

# This is what the numerical optimizer sees (only the calibrated entries).
calibrated_value(p :: Param{F1}) where F1 = 
    is_calibrated(p) ? pvalue(p) : nothing;


## ------------  Show

Base.show(io :: IO,  p :: Param{F1}) where F1 = 
    print(io, "Param:  " * show_string(p));




## ----------  Change / update

"""
    $(SIGNATURES)

Change calibration status to `true`
"""
function calibrate!(p :: Param{F1}) where F1
    p.isCalibrated = true
    return nothing
end


"""
    $(SIGNATURES)

Change calibration status to `false`
"""
function fix!(p :: Param{F1}; pValue = nothing) where F1
    p.isCalibrated = false;
    if !isnothing(pValue)
        set_value!(p, pValue);
        set_default_value!(p, pValue);
    end
    return nothing
end


"""
	$(SIGNATURES)

Set a random value for an `AbstractParam`.
"""
function set_random_value!(p :: Param{F1}, rng :: AbstractRNG) where F1
    sz = size(default_value(p));
    newValue = param_lb(p) .+ (param_ub(p) .- param_lb(p)) .* rand(rng, eltype(F1), sz);
    set_value!(p, newValue; skipInvalidSize = false);
end

# """
# 	$(SIGNATURES)

# Compare two Params. Report differences as Vector{Symbol}
# """
# function param_diffs(p1 :: Param{F1}, p2 :: Param{F2};
#     ignoreCalibrationStatus :: Bool = true) where {F1, F2}

#     diffs = Vector{Symbol}();
#     if (F1 == F2)  
#         if !isequal(value(p1), value(p2))
#             push!(diffs, :value);
#         end
#     else
#         push!(diffs, :type);
#     end
#     return diffs
# end


# -----------