## Constructor when not calibrated
function Param(name :: Symbol, description :: T2, symbol :: T2, defaultValue :: T1) where {T1 <: Any,  T2 <: AbstractString}

    return Param(name, description, symbol, defaultValue, defaultValue,
        defaultValue .- 0.001, defaultValue .+ 0.001, false)
end


function validate(p :: Param{F1}; silent = true) where F1
    sizeV = size(default_value(p));
    isValid = true;
    if !Base.isempty(value(p))
        (size(value(p)) == sizeV)  ||  (isValid = false);
    end
    if !Base.isempty(p.lb)
        (size(p.lb) == sizeV)  ||  (isValid = false);
        (size(p.ub) == sizeV)  ||  (isValid = false);
    end
    if !isValid  &&  !silent
        @warn """
            Invalid Param $p
            default value:  $(default_value(p))
            value:          $(value(p))
            lb:             $(p.lb)
            ub:             $(p.ub)
        """
    end
    return isValid
end

name(p :: Param{F1}) where F1 = p.name;

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


function show(io :: IO,  p :: Param{F1}) where F1
    print(io, "Param:  " * show_string(p));
    return nothing
end


function short_string(p :: Param{F1}) where F1
    vStr = formatted_value(value(p));
    return "$(p.name): $vStr"
end


"""
    report_param

Short summary of parameter and its value. 
Can be used to generate a simple table of calibrated parameters.
"""
function report_param(p :: Param{F1}) where F1
    vStr = formatted_value(value(p));
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

Set bounds for a `Param`.
"""
function set_bounds!(p :: Param{F1}; lb = nothing, ub = nothing) where F1
    isnothing(lb)  ||  (p.lb = lb);
    isnothing(ub)  ||  (p.ub = ub);
    @assert size(p.lb) == size(p.ub) == size(default_value(p));
end


"""
    $(SIGNATURES)
    
Set parameter value. Used during calibration.
"""
function set_value!(p :: Param{F1}, vIn) where F1
    @assert size(default_value(p)) == size(vIn)  "Size invalid for $(p.name): $(size(vIn)). Expected $(size(default_value(p)))"
    oldValue = value(p);
    p.value = deepcopy(vIn);
    return oldValue
end

function set_default_value!(p :: Param{F1}, vIn) where F1
    @assert size(default_value(p)) == size(vIn)  "Size invalid for $(p.name): $(size(vIn)). Expected $(size(default_value(p)))"
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
        default_value(p) = defaultValue;
    end
    if !isnothing(isCalibrated)
        p.isCalibrated = isCalibrated;
    end
    return nothing
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