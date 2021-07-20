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

"""
	$(SIGNATURES)

Retrieve value of a `Param`.
"""
value(p :: Param{F1}) where F1 = p.value;
   
default_value(p :: AbstractParam) = p.defaultValue;
lb(p :: AbstractParam) = p.lb;
ub(p :: AbstractParam) = p.ub;

# This is what the numerical optimizer sees (only the calibrated entries).
calibrated_value(p :: Param{F1}) where F1 = 
    is_calibrated(p) ? value(p) : nothing;
calibrated_lb(p :: AbstractParam) = lb(p);
calibrated_ub(p :: AbstractParam) = ub(p);

# Is a parameter value close to lower or upper bounds?
close_to_lb(p :: AbstractParam; rtol = 0.01)  = 
    any((value(p) .- lb(p)) ./ (ub(p) .- lb(p)) .< rtol);

close_to_ub(p :: AbstractParam; rtol = 0.01)  = 
    any((ub(p) .- value(p)) ./ (ub(p) .- lb(p)) .< rtol);

close_to_bounds(p :: AbstractParam; rtol = 0.01) where F1 = 
    close_to_lb(p; rtol = rtol) || close_to_ub(p; rtol = rtol);


## ------------  Show

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


Base.show(io :: IO,  p :: Param{F1}) where F1 = 
    print(io, "Param:  " * show_string(p));


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



## ----------  Change / update

function set_calibration_status!(p :: AbstractParam, isCalibrated :: Bool) 
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
    skipInvalidSize = false) where F1

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