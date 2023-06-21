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

# For compatibility with old format
function make_param(name :: Symbol, description :: AbstractString, sym :: AbstractString,
        value :: T1, defaultValue :: T1, lb :: T1, ub :: T1, isCalibrated :: Bool) where T1
    return Param(name, description, sym, value, defaultValue, lb, ub, isCalibrated);
end

## Constructor when not calibrated (deprecated)
function Param(name :: Symbol, description :: T2, symbol :: T2, defaultValue :: T1) where {T1 <: Any,  T2 <: AbstractString}

    return Param(name, description, symbol, defaultValue, defaultValue,
        defaultValue .- 0.001, defaultValue .+ 0.001, false)
end


function validate(p :: Param{F1}; silent = true) where F1
    sizeV = size(default_value(p));
    isValid = true;
    if !Base.isempty(calibrated_value(p))
        (size(calibrated_value(p)) == sizeV)  ||  (isValid = false);
    end
    if !Base.isempty(calibrated_lb(p))
        (size(calibrated_lb(p)) == sizeV)  ||  (isValid = false);
        (size(calibrated_ub(p)) == sizeV)  ||  (isValid = false);
    end
    if !isValid  &&  !silent
        @warn """
            Invalid Param $p
            default value:  $(default_value(p))
            value:          $(pvalue(p))
            lb:             $(calibrated_lb(p))
            ub:             $(calibrated_ub(p))
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

Retrieve value of a `Param`. User facing.
"""
pvalue(p :: Param) = p.value;
pvalue(p :: Param, j) = p.value[j];

# pvalue(::IdentityMap, p :: Param) = p.value;
# pvalue(::IdentityMap, p :: Param, j) = p.value[j];

# default_value(p :: Param) = p.defaultValue;
# default_value(::IdentityMap, p :: Param) = p.defaultValue;
   



## ------------  Show

Base.show(io :: IO,  p :: Param{F1}) where F1 = 
    print(io, "Param:  " * show_string(p));

type_description(p :: Param{F1}) where F1 <: Real = "Scalar";
type_description(p :: Param{F1}) where F1 <: AbstractVector = "Vector";
type_description(p :: Param{F1}) where F1 <: AbstractArray = "Array";



## ----------  Change / update

# """
#     $(SIGNATURES)

# Change calibration status to `true`
# """
# function calibrate!(p :: Param{F1}) where F1
#     p.isCalibrated = true
#     return nothing
# end


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