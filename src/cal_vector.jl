export CalVector, make_cal_vector, make_test_cal_vector;
export set_all_default_values!, set_some_default_values!;

function make_cal_vector(name :: Symbol, defaultValue :: T1;
    description = string(name), symbol = string(name), 
    lb = defaultValue .- 0.001, ub = defaultValue .+ 0.001,
    isCalibrated = falses(length(defaultValue))) where T1

    return CalVector(name, description, symbol, 
        copy(defaultValue), copy(defaultValue), copy(lb), copy(ub), 
        Vector{Bool}(copy(isCalibrated)))
end

function make_test_cal_vector(cal)
    v = [1.0, 3.0, 6.0];
    if cal == :all
        isCalV = trues(length(v));
    elseif cal == :none
        isCalV = falses(length(v));
    else
        isCalV = [true, false, true];
    end
    p = make_cal_vector(:x, v; 
        lb = v .- 2.0, ub = v .+ 2.0, 
        isCalibrated = isCalV);
    return p
end

function validate(p :: CalVector{T1}; silent :: Bool = true) where T1
    isValid = true;
    # Calibrated values only
    if is_calibrated(p)
        sizeV = size(default_value(p));
        calV = calibrated_value(p);
        defaultV = default_value(p);
        lb = calibrated_lb(p);
        ub = calibrated_ub(p);
        if (size(calV) != sizeV) || (size(defaultV) != sizeV) || 
                (size(lb) != sizeV) || (size(ub) != sizeV)
            isValid = false;
        end
    else
        if !ismissing(default_value(p))
            isValid = false;
        end
    end
    v = pvalue(p);

    if !isValid  &&  !silent
        @warn """
            Invalid CalVector $p
            default value:  $(default_value(p))
            value:          $(pvalue(p))
            lb:             $(calibrated_lb(p))
            ub:             $(calibrated_ub(p))
        """
    end
    return isValid
end

function n_calibrated(p :: CalVector)
    return sum(p.isCalibrated)
end

function is_calibrated(p :: CalVector)
    return any(p.isCalibrated)
end

function idx_calibrated(p :: CalVector)
    return findall(p.isCalibrated)
end

function idx_fixed(p :: CalVector)
    return findall(.!p.isCalibrated)
end

function calibrate!(p :: CalVector)
    p.isCalibrated .= true;
end

function calibrate!(p :: CalVector, idx :: AbstractVector)
    p.isCalibrated[idx] .= true;
end

function calibrate!(p :: CalVector, idx :: Integer)
    p.isCalibrated[idx] = true;
end

function fix!(p :: CalVector)
    p.isCalibrated .= false;
end

function fix!(p :: CalVector, idx :: AbstractVector)
    p.isCalibrated[idx] .= false;
end

function fix!(p :: CalVector, idx :: Integer)
    p.isCalibrated[idx] = false;
end

"""
In contrast to other params, returns missing if not calibrated. 
The reason is that CalVector does not have "potentially calibrated" param values.
"""
function calibrated_value_only(p :: CalVector)
    if is_calibrated(p)
        return p.value[idx_calibrated(p)];
    else
        return missing;
    end
end

function calibrated_value_user_facing(p :: CalVector)
    return pvalue(p);
end

function default_value_user_facing(p :: CalVector)
    return p.defaultValue;
end

# Only for the CALIBRATED values
function default_value(p :: CalVector)
    if is_calibrated(p)
        return p.defaultValue[idx_calibrated(p)];
    else
        return missing;
    end
end

function calibrated_lb(p :: CalVector)
    return p.lb[idx_calibrated(p)];
end

function calibrated_ub(p :: CalVector)
    return p.ub[idx_calibrated(p)];
end

function pvalue(p :: CalVector) 
    v = copy(p.defaultValue);
    for j = 1 : length(v)
        if p.isCalibrated[j]
            v[j] = p.value[j];
        end
    end
    return v
end

"""
Set calibrated values to `vIn`. If there are none, `vIn` should be `missing
"""
function set_calibrated_value!(p :: CalVector, vIn;
        skipInvalidSize = false)
    oldValue = calibrated_value(p; returnIfFixed = true);
    nCal = n_calibrated(p);
    if nCal == 0
        if !ismissing(vIn)
            @warn("No calibrated values in $p. Input should be missing.")
        end
    elseif nCal == length(vIn)  
        p.value[p.isCalibrated] .= vIn;
    else
        @warn("""
            Wrong size for $p
            Given: $(length(vIn))
            Expected: $(nCal)
            """);
        if !skipInvalidSize
            error("Stopped");
        end
    end
    return oldValue
end

"""
Set default values for the calibrated values.
Inputs are for calibrated values only. For consistency with other param types.
To set all default values, use `set_all_default_values!`.
If nothing is calibrated, input should be missing.
"""
function set_default_value!(p :: CalVector, vIn)
    if is_calibrated(p)
        p.defaultValue[p.isCalibrated] .= vIn;
    else
        @assert ismissing(vIn)  "Expected missing. Not calibrated: $p";
    end
end

function set_all_default_values!(p :: CalVector, vIn :: AbstractVector)
    @assert size(vIn) == size(p.defaultValue);
    p.defaultValue .= vIn;
end

function set_all_default_values!(p :: CalVector, vIn :: Number)
    p.defaultValue .= vIn;
end

function set_some_default_values!(p :: CalVector, idx :: AbstractVector, vIn)
    p.defaultValue[idx] .= vIn;
end

function set_some_default_values!(p :: CalVector, idx :: Integer, vIn)
    p.defaultValue[idx] = vIn;
end


# +++++ for all or only for calibrated?
function set_random_value!(p :: CalVector, rng :: AbstractRNG)
    sz = n_calibrated(p);
    F1 = typeof(default_value(p));
    newValue = calibrated_lb(p) .+ 
        (calibrated_ub(p) .- calibrated_lb(p)) .* rand(rng, eltype(F1), sz);
    set_calibrated_value!(p, newValue; skipInvalidSize = false);
end


## ------------  Show

Base.show(io :: IO,  p :: CalVector{F1}) where F1 = 
    print(io, "CalVector:  " * show_string(p));



# ---------------