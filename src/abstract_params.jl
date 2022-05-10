## -----------  Access

Base.size(p :: AbstractParam) = size(default_value(p));
Base.length(p :: AbstractParam) = length(default_value(p));

name(p :: AbstractParam) = p.name;
lsymbol(p :: AbstractParam) = p.symbol;

"""
	$(SIGNATURES)

Is this parameter calibrated?
"""
is_calibrated(p :: AbstractParam) = p.isCalibrated;

default_value(p :: AbstractParam) = p.defaultValue;
lb(p :: AbstractParam) = p.lb;
ub(p :: AbstractParam) = p.ub;

calibrated_lb(p :: AbstractParam) = lb(p);
calibrated_ub(p :: AbstractParam) = ub(p);

# Is a parameter value close to lower or upper bounds?
close_to_lb(p :: AbstractParam; rtol = 0.01)  = 
    any((value(p) .- lb(p)) ./ (ub(p) .- lb(p)) .< rtol);

close_to_ub(p :: AbstractParam; rtol = 0.01)  = 
    any((ub(p) .- value(p)) ./ (ub(p) .- lb(p)) .< rtol);

close_to_bounds(p :: AbstractParam; rtol = 0.01) where F1 = 
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
    pType = eltype(value(p));
    if isa(value(p), Real)
        outStr = string(round(value(p), digits = 3));
    elseif isa(value(p), Array)
        outStr = "Array{$pType} of size $(size(value(p)))";
    else
        outStr = "of type $pType";
    end
    return outStr
end


function short_string(p :: AbstractParam)
    vStr = formatted_value(value(p));
    return "$(name(p)): $vStr"
end


"""
    report_param

Short summary of parameter and its value. 
Can be used to generate a simple table of calibrated parameters.
"""
function report_param(p :: AbstractParam)
    vStr = formatted_value(value(p));
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
    @assert size(ModelParams.lb(p)) == size(ModelParams.ub(p)) == size(p);
end


"""
    $(SIGNATURES)
    
Set parameter value. Not used during calibration.
"""
function set_value!(p :: AbstractParam, vIn;
    skipInvalidSize = false)

    oldValue = value(p);
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

# This is used during the calibration
set_calibrated_value!(p :: AbstractParam, vIn; skipInvalidSize = false) = 
    set_value!(p, vIn; skipInvalidSize);

function set_default_value!(p :: AbstractParam, vIn) 
    @assert size(default_value(p)) == size(vIn)  "Size invalid for $(p.name): $(size(vIn)). Expected $(size(default_value(p)))"
    p.defaultValue = vIn
end


"""
    $(SIGNATURES)

Update a parameter with optional arguments.
"""
function update!(p :: AbstractParam; value = nothing, defaultValue = nothing,
    lb = nothing, ub = nothing, isCalibrated = nothing) 
    if !isnothing(value)
        set_value!(p, value)
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