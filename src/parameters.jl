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
value(p :: Param) = p.value;
lb(p :: Param) = p.lb;
ub(p :: Param) = p.ub;
lsymbol(p :: Param) = p.symbol;

# Is a parameter value close to lower or upper bounds?
close_to_lb(p :: Param; rtol = 0.01) = 
    any((value(p) .- lb(p)) ./ (ub(p) .- lb(p)) .< rtol);

close_to_ub(p :: Param; rtol = 0.01) = 
    any((ub(p) .- value(p)) ./ (ub(p) .- lb(p)) .< rtol);

close_to_bounds(p :: Param; rtol = 0.01) = 
    close_to_lb(p; rtol = rtol) || close_to_ub(p; rtol = rtol);


## ------------  Show

# Short string that summarizes the `Param`
# For reporting parameters in a table
function show_string(p :: Param)
    if p.isCalibrated
        calStr = "calibrated";
    else
        calStr = "fixed";
    end
    return string(p.name) * ": " * value_string(p) * "  ($calStr)"
end

# Summary of the value
function value_string(p :: Param)
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


function show(io :: IO,  p :: Param)
    println(io, "Param:  " * show_string(p));
    return nothing
end


function short_string(p :: Param)
    vStr = formatted_value(p.value);
    return "$(p.name): $vStr"
end


"""
    report_param

Short summary of parameter and its value. 
Can be used to generate a simple table of calibrated parameters.
"""
function report_param(p :: Param)
    vStr = formatted_value(p.value);
    println("\t$(p.description):\t$(p.name) = $vStr")
end



## ----------  Change / update

"""
    $(SIGNATURES)

Change calibration status to `true`
"""
function calibrate!(p :: Param)
    p.isCalibrated = true
    return nothing
end


"""
    $(SIGNATURES)

Change calibration status to `false`
"""
function fix!(p :: Param)
    p.isCalibrated = false
    return nothing
end


"""
    $(SIGNATURES)
    
Set parameter value. Used during calibration.
"""
function set_value!(p :: Param, vIn)
    @assert size(p.defaultValue) == size(vIn)  "Size invalid for $(p.name): $(size(vIn)). Expected $(size(p.defaultValue))"
    oldValue = p.value;
    p.value = deepcopy(vIn);
    return oldValue
end

function set_default_value!(p :: Param, vIn)
    @assert size(p.defaultValue) == size(vIn)  "Size invalid for $(p.name): $(size(vIn)). Expected $(size(p.defaultValue))"
    p.defaultValue = vIn
end


"""
    $(SIGNATURES)

Update a parameter with optional arguments.
"""
function update!(p :: Param; value = nothing, defaultValue = nothing,
    lb = nothing, ub = nothing, isCalibrated = nothing)
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