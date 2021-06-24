## Constructor when not calibrated
function Param(name :: Symbol, description :: T2, symbol :: T2, defaultValue :: T1) where {T1 <: Any,  T2 <: AbstractString}

    return Param(name, description, symbol, defaultValue, defaultValue,
        defaultValue .- 0.001, defaultValue .+ 0.001, false)
end


function validate(p :: Param{F1}) where F1
    sizeV = size(p.defaultValue);
    if !Base.isempty(p.value)
        @assert size(p.value) == sizeV
    end
    if !Base.isempty(p.lb)
        @assert size(p.lb) == sizeV
        @assert size(p.ub) == sizeV
    end
    return nothing
end

name(p :: Param) = p.name;

"""
	$(SIGNATURES)

Is this parameter calibrated?
"""
is_calibrated(p :: Param{F1}) where F1 = p.isCalibrated;

"""
	$(SIGNATURES)

Retrieve value of a `Param`.
"""
value(p :: Param{F1}) where F1 = p.value;
default_value(p :: Param{F1}) where F1 = p.defaultValue;
lb(p :: Param{F1}) where F1 = p.lb;
ub(p :: Param{F1}) where F1 = p.ub;
lsymbol(p :: Param{F1}) where F1 = p.symbol;

# Is a parameter value close to lower or upper bounds?
close_to_lb(p :: Param{F1}; rtol = 0.01) where F1 = 
    any((value(p) .- lb(p)) ./ (ub(p) .- lb(p)) .< rtol);

close_to_ub(p :: Param{F1}; rtol = 0.01) where F1 = 
    any((ub(p) .- value(p)) ./ (ub(p) .- lb(p)) .< rtol);

close_to_bounds(p :: Param{F1}; rtol = 0.01) where F1 = 
    close_to_lb(p; rtol = rtol) || close_to_ub(p; rtol = rtol);


## ------------  Show

# Short string that summarizes the `Param`
# For reporting parameters in a table
function show_string(p :: Param{F1}) where F1
    if p.isCalibrated
        calStr = "calibrated";
    else
        calStr = "fixed";
    end
    return string(p.name) * ": " * value_string(p) * "  ($calStr)"
end

# Summary of the value
function value_string(p :: Param{F1}) where F1
    pType = eltype(p.value);
    if isa(p.value, Real)
        outStr = string(round(p.value, digits = 3));
    elseif isa(p.value, Array)
        outStr = "Array{$pType} of size $(size(p.value))";
    else
        outStr = "of type $pType";
    end
    return outStr
end


function show(io :: IO,  p :: Param{F1}) where F1
    print(io, "Param:  " * show_string(p));
    return nothing
end


function short_string(p :: Param{F1}) where F1
    vStr = formatted_value(p.value);
    return "$(p.name): $vStr"
end


"""
    report_param

Short summary of parameter and its value. 
Can be used to generate a simple table of calibrated parameters.
"""
function report_param(p :: Param{F1}) where F1
    vStr = formatted_value(p.value);
    println("\t$(p.description):\t$(p.name) = $vStr")
end



## ----------  Change / update

function set_calibration_status!(p :: Param{F1}, isCalibrated :: Bool) where F1
    if isCalibrated
        calibrate!(p);
    else
        fix!(p);
    end
end

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
function fix!(p :: Param{F1}) where F1
    p.isCalibrated = false
    return nothing
end


"""
    $(SIGNATURES)
    
Set parameter value. Used during calibration.
"""
function set_value!(p :: Param{F1}, vIn) where F1
    @assert size(p.defaultValue) == size(vIn)  "Size invalid for $(p.name): $(size(vIn)). Expected $(size(p.defaultValue))"
    oldValue = p.value;
    p.value = deepcopy(vIn);
    return oldValue
end

function set_default_value!(p :: Param{F1}, vIn) where F1
    @assert size(p.defaultValue) == size(vIn)  "Size invalid for $(p.name): $(size(vIn)). Expected $(size(p.defaultValue))"
    p.defaultValue = vIn
end


"""
    $(SIGNATURES)

Update a parameter with optional arguments.
"""
function update!(p :: Param{F1}; value = nothing, defaultValue = nothing,
    lb = nothing, ub = nothing, isCalibrated = nothing) where F1
    if !isnothing(value)
        set_value!(p, value)
    end
    if !isnothing(lb)
        p.lb = lb;
    end
    if !isnothing(ub)
        p.ub = ub;
    end
    if !isnothing(defaultValue)
        p.defaultValue = defaultValue;
    end
    if !isnothing(isCalibrated)
        p.isCalibrated = isCalibrated;
    end
    return nothing
end


# -----------