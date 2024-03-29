## -----------  Access

# Size of calibrated params. Not size of user visible params.
Base.size(p :: AbstractParam) = size(default_value(p));
Base.length(p :: AbstractParam) = length(default_value(p));

name(p :: AbstractParam) = p.name;
lsymbol(p :: AbstractParam) = p.symbol;
pmeta(p :: AbstractParam) = IdentityMap(); 

"""
	$(SIGNATURES)

Number of calibrated parameters.
"""
function n_calibrated(p :: AbstractParam)
    if is_calibrated(p)
        return length(default_value(p));
    else
        return 0
    end
end

"""
	$(SIGNATURES)

Is this parameter calibrated?
"""
is_calibrated(p :: AbstractParam) = p.isCalibrated;

"""
	$(SIGNATURES)

Calibrated values. Not user facing. This is what the numerical optimizer sees (only the calibrated entries). Can be set to return `Missing` if parameter not calibrated.
"""
function calibrated_value(p :: AbstractParam; returnIfFixed = true)
    if is_calibrated(p) || returnIfFixed
        return calibrated_value_only(p);
    else
        return missing;
    end
end

"""
	$(SIGNATURES)

User facing version of calibrated value. Returns the calibrated value even if the parameter is fixed.
"""
calibrated_value_user_facing(p :: AbstractParam) = p.value;

default_value_user_facing(p :: AbstractParam) = p.defaultValue;

"""
	$(SIGNATURES)

Always returns calibrated value, even if param is fixed. NOT user facing.
"""
calibrated_value_only(p :: AbstractParam) = p.value;


"""
	$(SIGNATURES)

User facing parameter values. Constructed from calibrated and fixed values. Returns calibrated value if calibrated and fixed value if fixed.
"""
function pvalue(p :: AbstractParam)
    if is_calibrated(p)
        return calibrated_value_user_facing(p);
    else
        return default_value_user_facing(p);
    end
end

pvalue(p :: AbstractParam, j) = pvalue(p)[j];


"""
	$(SIGNATURES)

Default value of a parameter that is used when not calibrated.
Returns the values that could be calibrated. NOT user facing.
"""
default_value(p :: AbstractParam) = p.defaultValue;

"""
	$(SIGNATURES)

Lower bound used in calibration. Size matches calibrated values.
"""
calibrated_lb(p :: AbstractParam) = p.lb;

"""
	$(SIGNATURES)

Upper bound used in calibration. Size matches calibrated values.
"""
calibrated_ub(p :: AbstractParam) = p.ub;

# Deprecated because name not as clear as calibrated_lb.
param_lb(p :: AbstractParam) = calibrated_lb(p);
param_ub(p :: AbstractParam) = calibrated_ub(p);

# Is a parameter value close to lower or upper bounds?
function close_to_lb(p :: AbstractParam; rtol = 0.01)
    if is_calibrated(p)
        return any((calibrated_value(p) .- calibrated_lb(p)) ./ 
            (calibrated_ub(p) .- calibrated_lb(p)) .< rtol);
    else
        return false
    end
end

function close_to_ub(p :: AbstractParam; rtol = 0.01)
    if is_calibrated(p)
        return any((calibrated_ub(p) .- calibrated_value(p)) ./ 
            (calibrated_ub(p) .- param_lb(p)) .< rtol);
    else
        return false
    end
end

close_to_bounds(p :: AbstractParam; rtol = 0.01) = 
    close_to_lb(p; rtol = rtol) || close_to_ub(p; rtol = rtol);


## ----------  Show (generic)

# Short string that summarizes the `Param`
# For reporting parameters in a table
function show_string(p :: AbstractParam)
    if is_calibrated(p)
        calStr = "calibrated";
    else
        calStr = "fixed";
    end
    return string(p.name) * ": " * value_string(p) * "  ($calStr)"
end

# Summary of the value
function value_string(p :: AbstractParam)
    pType = eltype(pvalue(p));
    if isa(pvalue(p), Real)
        outStr = string(round(pvalue(p), digits = 3));
    elseif isa(pvalue(p), Array)
        outStr = "Array{$pType} of size $(size(pvalue(p)))";
    else
        outStr = "of type $pType";
    end
    return outStr
end


"""
	$(SIGNATURES)

One line description. To be shown in model summary.
"""
function short_description(p :: AbstractParam)
    pVal = pvalue(p);
    if is_calibrated(p)
        nCal = n_calibrated(p);
        s = "Calibrated ($nCal values)"
    else
        s = "Fixed of size $(size(pVal)) at " * formatted_value(pVal);
    end
    return type_description(p) * " / " * s
end

type_description(p :: T1) where T1 <: AbstractParam = "$T1";


function short_string(p :: AbstractParam)
    vStr = formatted_value(pvalue(p));
    return "$(name(p)): $vStr"
end


"""
    report_param

Short summary of parameter and its value. 
Can be used to generate a simple table of calibrated parameters.
"""
function report_param(p :: AbstractParam)
    vStr = formatted_value(pvalue(p));
    println("\t$(p.description):\t$(name(p)) = $vStr")
end


## -------------  Change

function set_calibration_status!(p :: AbstractParam, isCalibrated :: Bool) 
    if isCalibrated
        calibrate!(p);
    else
        fix!(p);
    end
end

"""
	$(SIGNATURES)

Set bounds for a `Param`.
"""
function set_bounds!(p :: AbstractParam; lb = nothing, ub = nothing) 
    isnothing(lb)  ||  (p.lb = lb);
    isnothing(ub)  ||  (p.ub = ub);
    @assert size(calibrated_lb(p)) == size(calibrated_ub(p)) == size(p);
end


"""
    $(SIGNATURES)
    
Set parameter value. Not used during calibration. Input is only calibrated values.
Invalid size errors, unless `skipInvalidSize == true`. Then the new value is ignored.

`vIn` is in internal units (not user facing).
"""
function set_calibrated_value!(p :: AbstractParam, vIn;
    skipInvalidSize = false)

    oldValue = calibrated_value(p; returnIfFixed = true);
    if size(default_value(p)) == size(vIn)  
        p.value = deepcopy(vIn);
    else
        @warn("""
            Wrong size for $p
            Given: $(size(vIn))
            Expected: $(size(default_value(p)))
            """);
        if !skipInvalidSize
            error("Stopped");
        end
    end
    return oldValue
end

"""
	$(SIGNATURES)

Set a random value for an `AbstractParam`.
"""
function set_random_value!(p :: AbstractParam, rng :: AbstractRNG)
    sz = size(default_value(p));
    F1 = typeof(default_value(p));
    newValue = calibrated_lb(p) .+ 
        (calibrated_ub(p) .- calibrated_lb(p)) .* rand(rng, eltype(F1), sz);
    set_calibrated_value!(p, newValue; skipInvalidSize = false);
end


"""
    $(SIGNATURES)

Change calibration status to `true`
"""
function calibrate!(p :: AbstractParam)
    p.isCalibrated = true;
    return nothing
end

"""
    $(SIGNATURES)

Change calibration status to `false`. `pValue` not in user facing units.
"""
function fix!(p :: AbstractParam; pValue = nothing)
    p.isCalibrated = false;
    if !isnothing(pValue)
        set_calibrated_value!(p, pValue);
        set_default_value!(p, pValue);
    end
    return nothing
end


# This is used during the calibration
# set_calibrated_value!(p :: AbstractParam, vIn; skipInvalidSize = false) = 
#     set_value!(p, vIn; skipInvalidSize);

# Input not user facing.
function set_default_value!(p :: AbstractParam, vIn) 
    @assert size(default_value(p)) == size(vIn)  "Size invalid for $(p.name): $(size(vIn)). Expected $(size(default_value(p)))"
    p.defaultValue = vIn
end


"""
    $(SIGNATURES)

Update a parameter with optional arguments. Values are in internal units (not user facing).
"""
function update!(p :: AbstractParam; value = nothing, defaultValue = nothing,
    lb = nothing, ub = nothing, isCalibrated = nothing) 
    if !isnothing(value)
        set_calibrated_value!(p, value);
    end
    if (!isnothing(lb))  ||  (!isnothing(ub))
        set_bounds!(p; lb, ub);
    end
    if !isnothing(defaultValue)
        set_default_value!(p, defaultValue);
    end
    if !isnothing(isCalibrated)
        set_calibration_status!(p, isCalibrated);
    end
    return nothing
end


# --------------------